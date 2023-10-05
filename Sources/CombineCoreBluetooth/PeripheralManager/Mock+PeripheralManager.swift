import Foundation

extension PeripheralManager {
  public static func unimplemented(
    state: @escaping @Sendable () -> CBManagerState = _Internal._unimplemented("state"),
    authorization: @escaping @Sendable () -> CBManagerAuthorization = _Internal._unimplemented("authorization"),
    isAdvertising: @escaping @Sendable () -> Bool = _Internal._unimplemented("isAdvertising"),
    startAdvertising: @escaping @Sendable (AdvertisementData?) -> Void = _Internal._unimplemented("startAdvertising"),
    stopAdvertising: @escaping @Sendable () -> Void = _Internal._unimplemented("stopAdvertising"),
    setDesiredConnectionLatency: @escaping @Sendable (CBPeripheralManagerConnectionLatency, Central) -> Void = _Internal._unimplemented("setDesiredConnectionLatency"),
    add: @escaping @Sendable (CBMutableService) -> Void = _Internal._unimplemented("add"),
    remove: @escaping @Sendable (CBMutableService) -> Void = _Internal._unimplemented("remove"),
    removeAllServices: @escaping @Sendable () -> Void = _Internal._unimplemented("removeAllServices"),
    respondToRequest: @escaping @Sendable (ATTRequest, CBATTError.Code) -> Void = _Internal._unimplemented("respondToRequest"),
    updateValueForCharacteristic: @escaping @Sendable (Data, CBMutableCharacteristic, [Central]?) -> Bool = _Internal._unimplemented("updateValueForCharacteristic"),
    publishL2CAPChannel: @escaping @Sendable (Bool) -> Void = _Internal._unimplemented("publishL2CAPChannel"),
    unpublishL2CAPChannel: @escaping @Sendable (CBL2CAPPSM) -> Void = _Internal._unimplemented("unpublishL2CAPChannel"),

    didUpdateState: AnyPublisher<CBManagerState, Never> = _Internal._unimplemented("didUpdateState"),
    didStartAdvertising: AnyPublisher<Error?, Never> = _Internal._unimplemented("didStartAdvertising"),
    didAddService: AnyPublisher<(CBService, Error?), Never> = _Internal._unimplemented("didAddService"),
    centralDidSubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never> = _Internal._unimplemented("centralDidSubscribeToCharacteristic"),
    centralDidUnsubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never> = _Internal._unimplemented("centralDidUnsubscribeToCharacteristic"),
    didReceiveReadRequest: AnyPublisher<ATTRequest, Never> = _Internal._unimplemented("didReceiveReadRequest"),
    didReceiveWriteRequests: AnyPublisher<[ATTRequest], Never> = _Internal._unimplemented("didReceiveWriteRequests"),
    readyToUpdateSubscribers: AnyPublisher<Void, Never> = _Internal._unimplemented("readyToUpdateSubscribers"),
    didPublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never> = _Internal._unimplemented("didPublishL2CAPChannel"),
    didUnpublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never> = _Internal._unimplemented("didUnpublishL2CAPChannel"),
    didOpenL2CAPChannel: AnyPublisher<(L2CAPChannel?, Error?), Never> = _Internal._unimplemented("didOpenL2CAPChannel")
  ) -> Self {
    self.init(
      delegate: nil,
      _state: state,
      _authorization: authorization,
      _isAdvertising: isAdvertising,
      _startAdvertising: startAdvertising,
      _stopAdvertising: stopAdvertising,
      _setDesiredConnectionLatency: setDesiredConnectionLatency,
      _add: add,
      _remove: remove,
      _removeAllServices: removeAllServices,
      _respondToRequest: respondToRequest,
      _updateValueForCharacteristic: updateValueForCharacteristic,
      _publishL2CAPChannel: publishL2CAPChannel,
      _unpublishL2CAPChannel: unpublishL2CAPChannel,
      didUpdateState: didUpdateState,
      didStartAdvertising: didStartAdvertising,
      didAddService: didAddService,
      centralDidSubscribeToCharacteristic: centralDidSubscribeToCharacteristic,
      centralDidUnsubscribeFromCharacteristic: centralDidUnsubscribeToCharacteristic,
      didReceiveReadRequest: didReceiveReadRequest,
      didReceiveWriteRequests: didReceiveWriteRequests,
      readyToUpdateSubscribers: readyToUpdateSubscribers,
      didPublishL2CAPChannel: didPublishL2CAPChannel,
      didUnpublishL2CAPChannel: didUnpublishL2CAPChannel,
      didOpenL2CAPChannel: didOpenL2CAPChannel
    )
  }
}
