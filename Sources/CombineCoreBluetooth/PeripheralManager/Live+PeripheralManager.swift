import Foundation
@preconcurrency import CoreBluetooth

extension PeripheralManager {
  public static func live(_ options: ManagerCreationOptions? = nil) -> Self {
    let delegate: Delegate = options?.restoreIdentifier != nil ? RestorableDelegate() : Delegate()
#if os(macOS) || os(iOS)
    let peripheralManager = CBPeripheralManager(
      delegate: delegate,
      queue: DispatchQueue(label: "combine-core-bluetooth.peripheral-manager", target: .global()),
      options: options?.peripheralManagerDictionary
    )
#else
    let peripheralManager = CBPeripheralManager()
    peripheralManager.delegate = delegate
#endif
    
    return Self(
      delegate: delegate,
      _state: { peripheralManager.state },
      _authorization: {
        if #available(iOS 13.1, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
          return CBPeripheralManager.authorization
        } else {
          return peripheralManager.authorization
        }
      },
      _isAdvertising: { peripheralManager.isAdvertising },
      _startAdvertising: { advertisementData in
        peripheralManager.startAdvertising(advertisementData?.dictionary)
      },
      _stopAdvertising: { peripheralManager.stopAdvertising() },
      _setDesiredConnectionLatency: { (latency, central) in
        peripheralManager.setDesiredConnectionLatency(latency, for: central.rawValue!)
      },
      _add: { peripheralManager.add($0) },
      _remove: { peripheralManager.remove($0) },
      _removeAllServices: { peripheralManager.removeAllServices() },
      _respondToRequest: { (request, result) in
        peripheralManager.respond(to: request.rawValue!, withResult: result)
      },
      _updateValueForCharacteristic: { (data, characteristic, centrals) -> Bool in
        peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: centrals?.compactMap(\.rawValue))
      },
      _publishL2CAPChannel: { peripheralManager.publishL2CAPChannel(withEncryption: $0) },
      _unpublishL2CAPChannel: { peripheralManager.unpublishL2CAPChannel($0) },
      
      didUpdateState: delegate.didUpdateState.eraseToAnyPublisher(),
      didStartAdvertising: delegate.didStartAdvertising.eraseToAnyPublisher(),
      didAddService: delegate.didAddService.eraseToAnyPublisher(),
      centralDidSubscribeToCharacteristic: delegate.centralDidSubscribeToCharacteristic.eraseToAnyPublisher(),
      centralDidUnsubscribeFromCharacteristic: delegate.centralDidUnsubscribeFromCharacteristic.eraseToAnyPublisher(),
      didReceiveReadRequest: delegate.didReceiveReadRequest.eraseToAnyPublisher(),
      didReceiveWriteRequests: delegate.didReceiveWriteRequests.eraseToAnyPublisher(),
      readyToUpdateSubscribers: delegate.readyToUpdateSubscribers.eraseToAnyPublisher(),
      didPublishL2CAPChannel: delegate.didPublishL2CAPChannel.eraseToAnyPublisher(),
      didUnpublishL2CAPChannel: delegate.didUnpublishL2CAPChannel.eraseToAnyPublisher(),
      didOpenL2CAPChannel: delegate.didOpenL2CAPChannel.eraseToAnyPublisher()
    )
  }
}

extension PeripheralManager.Delegate: CBPeripheralManagerDelegate {
  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    didUpdateState.send(peripheral.state)
  }
  
  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    didStartAdvertising.send(error)
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    didAddService.send((service, error))
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
    centralDidSubscribeToCharacteristic.send((.init(cbcentral: central), characteristic))
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
    centralDidUnsubscribeFromCharacteristic.send((.init(cbcentral: central), characteristic))
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    didReceiveReadRequest.send(.init(cbattrequest: request))
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    didReceiveWriteRequests.send(requests.map(ATTRequest.init(cbattrequest:)))
  }
  
  func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    readyToUpdateSubscribers.send()
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
    didPublishL2CAPChannel.send((PSM, error))
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
    didUnpublishL2CAPChannel.send((PSM, error))
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
    didOpenL2CAPChannel.send((channel.map(L2CAPChannel.init(channel:)), error))
  }
}

extension PeripheralManager.RestorableDelegate {
  func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
    willRestoreState.send(dict)
  }
}
