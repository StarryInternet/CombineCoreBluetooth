import Foundation

extension PeripheralManager {
  public static var live: Self {
    let delegate = Delegate()
    #if os(tvOS) || os(watchOS)
    let peripheralManager = CBPeripheralManager()
    peripheralManager.delegate = delegate
    #else
    let peripheralManager = CBPeripheralManager(
      delegate: delegate,
      queue: DispatchQueue(label: "com.combine-core-bluetooth.peripheral", target: .global())
    )
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
      _stopAdvertising: peripheralManager.stopAdvertising,
      _setDesiredConnectionLatency: { (latency, central) in
        peripheralManager.setDesiredConnectionLatency(latency, for: central.rawValue!)
      },
      _add: peripheralManager.add(_:),
      _remove: peripheralManager.remove(_:),
      _removeAllServices: peripheralManager.removeAllServices,
      _respondToRequest: { (request, result) in
        peripheralManager.respond(to:request.rawValue!, withResult: result)
      },
      _updateValueForCharacteristic: { (data, characteristic, centrals) -> Bool in
        peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: centrals?.compactMap(\.rawValue))
      },
      _publishL2CAPChannel: peripheralManager.publishL2CAPChannel(withEncryption:),
      _unpublishL2CAPChannel: peripheralManager.unpublishL2CAPChannel(_:),

      didUpdateState: delegate.didUpdateState,
      didStartAdvertising: delegate.didStartAdvertising,
      didAddService: delegate.didAddService,
      centralDidSubscribeToCharacteristic: delegate.centralDidSubscribeToCharacteristic,
      centralDidUnsubscribeFromCharacteristic: delegate.centralDidUnsubscribeFromCharacteristic,
      didReceiveReadRequest: delegate.didReceiveReadRequest,
      didReceiveWriteRequests: delegate.didReceiveWriteRequests,
      readyToUpdateSubscribers: delegate.readyToUpdateSubscribers,
      didPublishL2CAPChannel: delegate.didPublishL2CAPChannel,
      didUnpublishL2CAPChannel: delegate.didUnpublishL2CAPChannel,
      didOpenL2CAPChannel: delegate.didOpenL2CAPChannel
    )
  }
}

extension PeripheralManager {
  @objc(CCBPeripheralManagerDelegate)
  class Delegate: NSObject, CBPeripheralManagerDelegate {
    @PassthroughBacked var didUpdateState: AnyPublisher<CBManagerState, Never>
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
      _didUpdateState.send(peripheral.state)
    }

    @PassthroughBacked var willRestoreState: AnyPublisher<[String: Any], Never>
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
      _willRestoreState.send(dict)
    }

    @PassthroughBacked var didStartAdvertising: AnyPublisher<Error?, Never>
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
      _didStartAdvertising.send(error)
    }

    @PassthroughBacked var didAddService: AnyPublisher<(CBService, Error?), Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
      _didAddService.send((service, error))
    }

    @PassthroughBacked var centralDidSubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
      _centralDidSubscribeToCharacteristic.send((.init(cbcentral: central), characteristic))
    }

    @PassthroughBacked var centralDidUnsubscribeFromCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
      _centralDidUnsubscribeFromCharacteristic.send((.init(cbcentral: central), characteristic))
    }

    @PassthroughBacked var didReceiveReadRequest: AnyPublisher<ATTRequest, Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
      _didReceiveReadRequest.send(.init(cbattrequest: request))
    }

    @PassthroughBacked var didReceiveWriteRequests: AnyPublisher<[ATTRequest], Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
      _didReceiveWriteRequests.send(requests.map(ATTRequest.init(cbattrequest:)))
    }

    @PassthroughBacked var readyToUpdateSubscribers: AnyPublisher<Void, Never>
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
      _readyToUpdateSubscribers.send()
    }

    @PassthroughBacked var didPublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
      _didPublishL2CAPChannel.send((PSM, error))
    }

    @PassthroughBacked var didUnpublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
      _didUnpublishL2CAPChannel.send((PSM, error))
    }

    @PassthroughBacked var didOpenL2CAPChannel: AnyPublisher<(L2CAPChannel?, Error?), Never>
    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
      _didOpenL2CAPChannel.send((channel.map(L2CAPChannel.init(channel:)), error))
    }
  }
}
