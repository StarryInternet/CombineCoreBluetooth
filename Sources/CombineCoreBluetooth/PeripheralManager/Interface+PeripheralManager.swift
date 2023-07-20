import Foundation
import CoreBluetooth
import Combine

public struct PeripheralManager {
  let delegate: Delegate?

  let _state: () -> CBManagerState
  let _authorization: () -> CBManagerAuthorization
  let _isAdvertising: () -> Bool
  let _startAdvertising: (_ advertisementData: AdvertisementData?) -> Void
  let _stopAdvertising: () -> Void
  let _setDesiredConnectionLatency: (_ latency: CBPeripheralManagerConnectionLatency, _ central: Central) -> Void
  let _add: (_ service: CBMutableService) -> Void
  let _remove: (_ service: CBMutableService) -> Void
  let _removeAllServices: () -> Void
  let _respondToRequest: (_ request: ATTRequest, _ result: CBATTError.Code) -> Void
  let _updateValueForCharacteristic: (_ value: Data, _ characteristic: CBMutableCharacteristic, _ centrals: [Central]?) -> Bool
  let _publishL2CAPChannel: (_ encryptionRequired: Bool) -> Void
  let _unpublishL2CAPChannel: (_ PSM: CBL2CAPPSM) -> Void

  public let didUpdateState: AnyPublisher<CBManagerState, Never>
  public let didStartAdvertising: AnyPublisher<Error?, Never>
  public let didAddService: AnyPublisher<(CBService, Error?), Never>
  public let centralDidSubscribeToCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never>
  public let centralDidUnsubscribeFromCharacteristic: AnyPublisher<(Central, CBCharacteristic), Never>
  public let didReceiveReadRequest: AnyPublisher<ATTRequest, Never>
  public let didReceiveWriteRequests: AnyPublisher<[ATTRequest], Never>
  public let readyToUpdateSubscribers: AnyPublisher<Void, Never>
  public let didPublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never>
  public let didUnpublishL2CAPChannel: AnyPublisher<(CBL2CAPPSM, Error?), Never>
  public let didOpenL2CAPChannel: AnyPublisher<(L2CAPChannel?, Error?), Never>

  public var state: CBManagerState {
    _state()
  }
  
  public var authorization: CBManagerAuthorization {
    _authorization()
  }

  public var isAdvertising: Bool {
    _isAdvertising()
  }

  public func startAdvertising(_ advertisementData: AdvertisementData?) {
    _startAdvertising(advertisementData)
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

  public func publishL2CAPChannel(withEncryption encryptionRequired: Bool) {
    _publishL2CAPChannel(encryptionRequired)
  }

  public func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) {
    _unpublishL2CAPChannel(PSM)
  }
}
