import Foundation

extension PeripheralManager {
  public static func unimplemented(
    state: @escaping () -> CBManagerState = Internal._unimplemented("state"),
    authorization: @escaping () -> CBManagerAuthorization = Internal._unimplemented("authorization"),
    isAdvertising: @escaping () -> Bool = Internal._unimplemented("isAdvertising"),
    startAdvertising: @escaping (AdvertisementData?) -> Void = Internal._unimplemented("startAdvertising"),
    stopAdvertising: @escaping () -> Void = Internal._unimplemented("stopAdvertising"),
    setDesiredConnectionLatency: @escaping (CBPeripheralManagerConnectionLatency, Central) -> Void = Internal._unimplemented("setDesiredConnectionLatency"),
    add: @escaping (CBMutableService) -> Void = Internal._unimplemented("add"),
    remove: @escaping (CBMutableService) -> Void = Internal._unimplemented("remove"),
    removeAllServices: @escaping () -> Void = Internal._unimplemented("removeAllServices"),
    respondToRequest: @escaping (ATTRequest, CBATTError.Code) -> Void = Internal._unimplemented("respondToRequest"),
    updateValueForCharacteristic: @escaping (Data, CBMutableCharacteristic, [Central]?) -> Bool = Internal._unimplemented("updateValueForCharacteristic"),
    publishL2CAPChannel: @escaping (Bool) -> Void = Internal._unimplemented("publishL2CAPChannel"),
    unpublishL2CAPChannel: @escaping (CBL2CAPPSM) -> Void = Internal._unimplemented("unpublishL2CAPChannel"),

    didUpdateState: AnyPublisher<CBManagerState, Never> = Internal._unimplemented("didUpdateState"),
    didStartAdvertising: AnyPublisher<Error?, Never> = Internal._unimplemented("didStartAdvertising"),
    didAddService: AnyPublisher<(CBService, Error?), Never> = Internal._unimplemented("didAddService"),
    centralDidSubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never> = Internal._unimplemented("centralDidSubscribeToCharacteristic"),
    centralDidUnsubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never> = Internal._unimplemented("centralDidUnsubscribeToCharacteristic"),
    didReceiveReadRequest: AnyPublisher<ATTRequest, Never> = Internal._unimplemented("didReceiveReadRequest"),
    didReceiveWriteRequests: AnyPublisher<[ATTRequest], Never> = Internal._unimplemented("didReceiveWriteRequests"),
    readyToUpdateSubscribers: AnyPublisher<Void, Never> = Internal._unimplemented("readyToUpdateSubscribers"),
    didPublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never> = Internal._unimplemented("didPublishL2CAPChannel"),
    didUnpublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never> = Internal._unimplemented("didUnpublishL2CAPChannel"),
    didOpenL2CAPChannel: AnyPublisher<(L2CAPChannel?, Error?), Never> = Internal._unimplemented("didOpenL2CAPChannel")
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
