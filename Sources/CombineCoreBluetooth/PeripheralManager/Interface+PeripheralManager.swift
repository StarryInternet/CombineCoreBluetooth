import Foundation
@preconcurrency import Combine

public struct PeripheralManager: Sendable {
  let delegate: Delegate?

  public var _state: @Sendable () -> CBManagerState
  public var _authorization: @Sendable () -> CBManagerAuthorization
  public var _isAdvertising: @Sendable () -> Bool
  public var _startAdvertising: @Sendable (_ advertisementData: AdvertisementData?) -> Void
  public var _stopAdvertising: @Sendable () -> Void
  public var _setDesiredConnectionLatency: @Sendable (_ latency: CBPeripheralManagerConnectionLatency, _ central: Central) -> Void
  public var _add: @Sendable (_ service: CBMutableService) -> Void
  public var _remove: @Sendable (_ service: CBMutableService) -> Void
  public var _removeAllServices: @Sendable () -> Void
  public var _respondToRequest: @Sendable (_ request: ATTRequest, _ result: CBATTError.Code) -> Void
  public var _updateValueForCharacteristic: @Sendable (_ value: Data, _ characteristic: CBMutableCharacteristic, _ centrals: [Central]?) -> Bool
  public var _publishL2CAPChannel: @Sendable (_ encryptionRequired: Bool) -> Void
  public var _unpublishL2CAPChannel: @Sendable (_ PSM: CBL2CAPPSM) -> Void

  public var didUpdateState: AnyPublisher<CBManagerState, Never>
  public var didStartAdvertising: AnyPublisher<Error?, Never>
  public var didAddService: AnyPublisher<(CBService, Error?), Never>
  public var centralDidSubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never>
  public var centralDidUnsubscribeFromCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never>
  public var didReceiveReadRequest: AnyPublisher<ATTRequest, Never>
  public var didReceiveWriteRequests: AnyPublisher<[ATTRequest], Never>
  public var readyToUpdateSubscribers: AnyPublisher<Void, Never>
  public var didPublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never>
  public var didUnpublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never>
  public var didOpenL2CAPChannel: AnyPublisher<(L2CAPChannel?, Error?), Never>

  public var state: CBManagerState {
    _state()
  }
  
  public var authorization: CBManagerAuthorization {
    _authorization()
  }

  public var isAdvertising: Bool {
    _isAdvertising()
  }

  public func startAdvertising(_ advertisementData: AdvertisementData?) -> AnyPublisher<Void, Error> {
    Publishers.Merge(
      didUpdateState,
      // the act of checking state here will trigger core bluetooth to turn the radio on so that it eventually becomes `poweredOn` later in `didUpdateState`
      [state].publisher
    )
    .first(where: { $0 == .poweredOn })
    .flatMap { _ in
      // once powered on, we can begin advertising. Do so once this flatmap'd publisher is subscribed to, so we don't start too soon.
      didStartAdvertising
        .handleEvents(receiveSubscription: { _ in
          _startAdvertising(advertisementData)
        })
    }
    .tryMap { error in
      if let error = error {
        throw error
      }
    }
    .eraseToAnyPublisher()
  }
  
  public func stopAdvertising() {
    _stopAdvertising()
  }

  public func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: Central) {
    _setDesiredConnectionLatency(latency, central)
  }

  public func add(_ service: CBMutableService) {
    _add(service)
  }

  public func remove(_ service: CBMutableService) {
    _remove(service)
  }

  public func removeAllServices() {
    _removeAllServices()
  }

  public func respond(to request: ATTRequest, withResult result: CBATTError.Code) {
    _respondToRequest(request, result)
  }

  public func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [Central]?) -> AnyPublisher<Void, Error> {
    func update(retries: Int, _ value: Data, _ characteristic: CBMutableCharacteristic, _ centrals: [Central]?) -> AnyPublisher<Void, Error> {
      let success = _updateValueForCharacteristic(value, characteristic, centrals)
      if success {
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
      } else {
        if retries == 0 {
          return Fail(error: PeripheralManagerError.failedToUpdateCharacteristic(characteristic.uuid)).eraseToAnyPublisher()
        } else {
          return readyToUpdateSubscribers.first()
            .setFailureType(to: Error.self)
            .flatMap { _ in
              update(retries: retries-1, value, characteristic, centrals)
            }
            .eraseToAnyPublisher()
        }
      }
    }
    return update(retries: 4, value, characteristic, centrals)
  }

  public func publishL2CAPChannel(withEncryption encryptionRequired: Bool) -> AnyPublisher<CBL2CAPPSM, Error> {
    didPublishL2CAPChannel
      .first()
      .selectValueOrThrowError()
      .handleEvents(receiveSubscription: { _ in
        _publishL2CAPChannel(encryptionRequired)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) -> AnyPublisher<CBL2CAPPSM, Error> {
    didUnpublishL2CAPChannel
      .filterFirstValueOrThrow(where: { $0 == PSM })
      .handleEvents(receiveSubscription: { _ in
        _unpublishL2CAPChannel(PSM)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }
}

extension PeripheralManager {
  @objc(CCBPeripheralManagerDelegate)
  class Delegate: NSObject, @unchecked Sendable {
    let didUpdateState:                          PassthroughSubject<CBManagerState, Never>              = .init()
    let willRestoreState:                        PassthroughSubject<[String: Any], Never>               = .init()
    let didStartAdvertising:                     PassthroughSubject<Error?, Never>                      = .init()
    let didAddService:                           PassthroughSubject<(CBService, Error?), Never>         = .init()
    let centralDidSubscribeToCharacteristic:     PassthroughSubject<(Central, CBCharacteristic), Never> = .init()
    let centralDidUnsubscribeFromCharacteristic: PassthroughSubject<(Central, CBCharacteristic), Never> = .init()
    let didReceiveReadRequest:                   PassthroughSubject<ATTRequest, Never>                  = .init()
    let didReceiveWriteRequests:                 PassthroughSubject<[ATTRequest], Never>                = .init()
    let readyToUpdateSubscribers:                PassthroughSubject<Void, Never>                        = .init()
    let didPublishL2CAPChannel:                  PassthroughSubject<(CBL2CAPPSM, Error?), Never>        = .init()
    let didUnpublishL2CAPChannel:                PassthroughSubject<(CBL2CAPPSM, Error?), Never>        = .init()
    let didOpenL2CAPChannel:                     PassthroughSubject<(L2CAPChannel?, Error?), Never>     = .init()
  }
  
  @objc(CCBPeripheralManagerRestorableDelegate)
  class RestorableDelegate: Delegate, @unchecked Sendable {}
}
