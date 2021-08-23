import Combine
import CoreBluetooth
import Foundation

enum CentralManagerError: Error, Equatable {
  case failedToConnect(Peripheral, NSError?)
}

extension CentralManager {
  public static var live: Self {
    let delegate = Delegate()
    let centralManager = CBCentralManager(
      delegate: delegate,
      queue: DispatchQueue(label: "com.combine-core-bluetooth.central", target: .global())
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
        #if os(macOS)
        fatalError("This method is not callable on native macOS")
        #else
        return CBCentralManager.supports($0)
        #endif
      },
      _retrievePeripheralsWithIdentifiers: { (identifiers, manager) -> [Peripheral] in
        centralManager.retrievePeripherals(withIdentifiers: identifiers).map(Peripheral.init(cbperipheral:))
      },
      _retrieveConnectedPeripheralsWithServices: { (serviceIDs, manager) -> [Peripheral] in
        centralManager.retrieveConnectedPeripherals(withServices: serviceIDs).map(Peripheral.init(cbperipheral:))
      },
      _scanForPeripheralsWithServices: centralManager.scanForPeripherals(withServices:options:),
      _stopScanForPeripherals: centralManager.stopScan,
      _connectToPeripheral: { (peripheral, options) in
        Publishers.Merge(
          delegate.didConnectPeripheral
            .filter({ $0 == peripheral })
            .setFailureType(to: Error.self),
          delegate.didFailToConnectPeripheral
            .filter({ p, _ in p == peripheral })
            .tryMap({ p, error in
              throw CentralManagerError.failedToConnect(p, error as NSError?)
            })
        )
        .prefix(1)
        .handleEvents(receiveSubscription: { _ in
          centralManager.connect(peripheral.rawValue!, options: options)
        }, receiveCancel: {
          centralManager.cancelPeripheralConnection(peripheral.rawValue!)
        })
        .share()
        .eraseToAnyPublisher()
      },
      _cancelPeripheralConnection: { (peripheral) in
        centralManager.cancelPeripheralConnection(peripheral.rawValue!)
      },
      _registerForConnectionEvents: {
        #if os(macOS)
        fatalError("This method is not callable on native macOS")
        #else
        centralManager.registerForConnectionEvents(options: $0)
        #endif
      },

      didUpdateState: delegate.didUpdateState,
      willRestoreState: delegate.willRestoreState,
      didConnectPeripheral: delegate.didConnectPeripheral,
      didFailToConnectPeripheral: delegate.didFailToConnectPeripheral,
      didDisconnectPeripheral: delegate.didDisconnectPeripheral,
      connectionEventDidOccur: delegate.connectionEventDidOccur,
      didDiscoverPeripheral: delegate.didDiscoverPeripheral,
      didUpdateACNSAuthorizationForPeripheral: delegate.didUpdateACNSAuthorizationForPeripheral
    )
  }
}

extension CentralManager {
  class Delegate: NSObject, CBCentralManagerDelegate {
    @PassthroughBacked var didUpdateState: AnyPublisher<CBManagerState, Never>
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
      _didUpdateState.send(central.state)
    }

    @PassthroughBacked var willRestoreState: AnyPublisher<[String: Any], Never>
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
      _willRestoreState.send(dict)
    }

    @PassthroughBacked var didConnectPeripheral: AnyPublisher<Peripheral, Never>
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
      _didConnectPeripheral.send(Peripheral(cbperipheral: peripheral))
    }

    @PassthroughBacked var didFailToConnectPeripheral: AnyPublisher<(Peripheral, Error?), Never>
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
      _didFailToConnectPeripheral.send((Peripheral(cbperipheral: peripheral), error))
    }

    @PassthroughBacked var didDisconnectPeripheral: AnyPublisher<(Peripheral, Error?), Never>
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
      _didDisconnectPeripheral.send((Peripheral(cbperipheral: peripheral), error))
    }

    @PassthroughBacked var connectionEventDidOccur: AnyPublisher<(CBConnectionEvent, Peripheral), Never>
    #if os(iOS) || os(tvOS) || os(watchOS)
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
      _connectionEventDidOccur.send((event, Peripheral(cbperipheral: peripheral)))
    }
    #endif

    @PassthroughBacked var didDiscoverPeripheral: AnyPublisher<PeripheralDiscovery, Never>
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
      _didDiscoverPeripheral.send(PeripheralDiscovery(peripheral: Peripheral(cbperipheral: peripheral),
                                                      advertisementData: AdvertisementData(advertisementData),
                                                      rssi: RSSI.doubleValue))
    }

    @PassthroughBacked var didUpdateACNSAuthorizationForPeripheral: AnyPublisher<Peripheral, Never>
    #if os(iOS) || os(tvOS) || os(watchOS)
    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
      _didUpdateACNSAuthorizationForPeripheral.send(Peripheral(cbperipheral: peripheral))
    }
    #endif
  }
}
