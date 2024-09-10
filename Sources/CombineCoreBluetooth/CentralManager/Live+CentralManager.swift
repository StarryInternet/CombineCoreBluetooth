import Combine
@preconcurrency import CoreBluetooth
import Foundation

extension CentralManager {
  public static func live(_ options: ManagerCreationOptions? = nil) -> Self {
    let delegate: Delegate = options?.restoreIdentifier != nil ? RestorableDelegate() : Delegate()
    let centralManager = CBCentralManager(
      delegate: delegate,
      queue: DispatchQueue(label: "combine-core-bluetooth.central-manager", target: .global()),
      options: options?.centralManagerDictionary
    )
    
    return Self.init(
      delegate: delegate,
      _state: { centralManager.state },
      _authorization: {
        if #available(iOS 13.1, *) {
          return CBCentralManager.authorization
        } else {
          return centralManager.authorization
        }
      },
      _isScanning: { centralManager.isScanning },
      _supportsFeatures: {
#if os(macOS) && !targetEnvironment(macCatalyst)
        // will never be called on native macOS
#else
        CBCentralManager.supports($0)
#endif
      },
      _retrievePeripheralsWithIdentifiers: { (identifiers) -> [Peripheral] in
        centralManager.retrievePeripherals(withIdentifiers: identifiers).map(Peripheral.init(cbperipheral:))
      },
      _retrieveConnectedPeripheralsWithServices: { (serviceIDs) -> [Peripheral] in
        centralManager.retrieveConnectedPeripherals(withServices: serviceIDs).map(Peripheral.init(cbperipheral:))
      },
      _scanForPeripheralsWithServices: { services, options in
        centralManager.scanForPeripherals(withServices: services, options: options?.dictionary)
      },
      _stopScan: { centralManager.stopScan() },
      _connectToPeripheral: { (peripheral, options) in
        centralManager.connect(peripheral.rawValue!, options: options?.dictionary)
      },
      _cancelPeripheralConnection: { (peripheral) in
        centralManager.cancelPeripheralConnection(peripheral.rawValue!)
      },
      _registerForConnectionEvents: {
#if os(macOS) && !targetEnvironment(macCatalyst)
        fatalError("This method is not callable on native macOS")
#else
        centralManager.registerForConnectionEvents(options: $0)
#endif
      },
      
      didUpdateState: delegate.actionSubject.compactMap { $0.didUpdateState }.eraseToAnyPublisher(),
      willRestoreState: delegate.actionSubject.compactMap { $0.willRestoreState }.eraseToAnyPublisher(),
      didConnectPeripheral: delegate.actionSubject.compactMap { $0.didConnectPeripheral }.eraseToAnyPublisher(),
      didFailToConnectPeripheral: delegate.actionSubject.compactMap { $0.didFailToConnectPeripheral }.eraseToAnyPublisher(),
      didDisconnectPeripheral: delegate.actionSubject.compactMap { $0.didDisconnectPeripheral }.eraseToAnyPublisher(),
      connectionEventDidOccur: delegate.actionSubject.compactMap { $0.connectionEventDidOccur }.eraseToAnyPublisher(),
      didDiscoverPeripheral: delegate.actionSubject.compactMap { $0.didDiscoverPeripheral }.eraseToAnyPublisher(),
      didUpdateACNSAuthorizationForPeripheral: delegate.actionSubject.compactMap { $0.didUpdateACNSAuthorizationForPeripheral }.eraseToAnyPublisher()
    )
  }
}

extension CentralManager.ScanOptions {
  var dictionary: [String: Any] {
    var dict: [String: Any] = [:]
    dict[CBCentralManagerScanOptionAllowDuplicatesKey] = allowDuplicates
    dict[CBCentralManagerScanOptionSolicitedServiceUUIDsKey] = solicitedServiceUUIDs
    return dict
  }
}

extension CentralManager.PeripheralConnectionOptions {
  var dictionary: [String: Any] {
    var dict: [String: Any] = [:]
    dict[CBConnectPeripheralOptionNotifyOnConnectionKey] = notifyOnConnection
    dict[CBConnectPeripheralOptionNotifyOnDisconnectionKey] = notifyOnDisconnection
    dict[CBConnectPeripheralOptionNotifyOnNotificationKey] = notifyOnNotification
    dict[CBConnectPeripheralOptionStartDelayKey] = startDelay
    return dict
  }
}

extension CentralManager.Delegate: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    actionSubject.send(.didUpdateState(central.state))
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    actionSubject.send(.didConnectPeripheral(Peripheral(cbperipheral: peripheral)))
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    actionSubject.send(.didFailToConnectPeripheral((Peripheral(cbperipheral: peripheral), error)))
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    actionSubject.send(.didDisconnectPeripheral((Peripheral(cbperipheral: peripheral), error)))
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    actionSubject.send(.didDiscoverPeripheral(
      PeripheralDiscovery(
        peripheral: Peripheral(cbperipheral: peripheral),
        advertisementData: AdvertisementData(advertisementData),
        rssi: RSSI.doubleValue
      )
    ))
  }
  
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
  func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
    actionSubject.send(.connectionEventDidOccur((event, Peripheral(cbperipheral: peripheral))))
  }
  
  func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
    actionSubject.send(.didUpdateACNSAuthorizationForPeripheral(Peripheral(cbperipheral: peripheral)))
  }
#endif
}

extension CentralManager.RestorableDelegate {
  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    actionSubject.send(.willRestoreState(dict))
  }
}
