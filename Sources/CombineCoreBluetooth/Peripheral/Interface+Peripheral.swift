import Foundation
import CoreBluetooth

/// The `CombineCoreBluetooth` wrapper around `CBPeripheral`.
public struct Peripheral {
  let delegate: Delegate?

  var _name: () -> String?
  var _identifier: () -> UUID
  var _state: () -> CBPeripheralState
  var _services: () -> [CBService]?
  var _canSendWriteWithoutResponse: () -> Bool

  @available(macOS, unavailable)
  var _ancsAuthorized: () -> Bool

  var _readRSSI: () -> Void
  var _discoverServices: (_ serviceUUIDs: [CBUUID]?) -> Void
  var _discoverIncludedServices: (_ includedServiceUUIDs: [CBUUID]?, _ service: CBService) -> Void
  var _discoverCharacteristics: (_ characteristicUUIDs: [CBUUID]?, _ service: CBService) -> Void
  var _readValueForCharacteristic: (_ characteristic: CBCharacteristic) -> Void
  var _maximumWriteValueLength: (_ type: CBCharacteristicWriteType) -> Int
  var _writeValueForCharacteristic: (_ data: Data, _ characteristic: CBCharacteristic, _ type: CBCharacteristicWriteType) -> Void
  var _setNotifyValue: (_ enabled: Bool, _ characteristic: CBCharacteristic) -> Void
  var _discoverDescriptors: (_ characteristic: CBCharacteristic) -> Void
  var _readValueForDescriptor: (_ descriptor: CBDescriptor) -> Void
  var _writeValueForDescriptor: (_ data: Data, _ descriptor: CBDescriptor) -> Void
  var _openL2CAPChannel: (_ PSM: CBL2CAPPSM) -> Void

  var didReadRSSI:                             AnyPublisher<Result<Double, Error>, Never>
  var didDiscoverServices:                     AnyPublisher<([CBService], Error?), Never>
  var didDiscoverIncludedServices:             AnyPublisher<(CBService, Error?), Never>
  var didDiscoverCharacteristics:              AnyPublisher<(CBService, Error?), Never>
  var didUpdateValueForCharacteristic:         AnyPublisher<(CBCharacteristic, Error?), Never>
  var didWriteValueForCharacteristic:          AnyPublisher<(CBCharacteristic, Error?), Never>
  var didUpdateNotificationState:              AnyPublisher<(CBCharacteristic, Error?), Never>
  var didDiscoverDescriptorsForCharacteristic: AnyPublisher<(CBCharacteristic, Error?), Never>
  var didUpdateValueForDescriptor:             AnyPublisher<(CBDescriptor, Error?), Never>
  var didWriteValueForDescriptor:              AnyPublisher<(CBDescriptor, Error?), Never>
  var didOpenChannel:                          AnyPublisher<(L2CAPChannel?, Error?), Never>

  public var isReadyToSendWriteWithoutResponse: AnyPublisher<Void, Never>
  public var nameUpdates: AnyPublisher<String?, Never>
  public var invalidatedServiceUpdates: AnyPublisher<[CBService], Never>

  public var name: String? {
    _name()
  }

  public var identifier: UUID {
    _identifier()
  }

  public var state: CBPeripheralState {
    _state()
  }

  public var services: [CBService]? {
    _services()
  }

  public var canSendWriteWithoutResponse: Bool {
    _canSendWriteWithoutResponse()
  }

  @available(macOS, unavailable)
  public var ancsAuthorized: Bool {
    _ancsAuthorized()
  }

  public func readRSSI() -> AnyPublisher<Double, Error> {
    didReadRSSI
      .tryMap { result in
        try result.get()
      }
      .first()
      .handleEvents(receiveSubscription: { [_readRSSI] _ in
        _readRSSI()
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func discoverServices(_ serviceUUIDs: [CBUUID]?) -> AnyPublisher<[CBService], Error> {
    didDiscoverServices
      .filterFirstValueOrThrow(where: { services in
        // nil identifiers means we want to discover anything we can
        guard let identifiers = serviceUUIDs else { return true }
        // Only progress if the peripheral contains all the services we are looking for.
        let neededUUIDs = Set(identifiers)
        let foundUUIDs = Set(services.map(\.uuid))
        let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
        return allFound
      }) //
      .handleEvents(receiveSubscription: { [_discoverServices] _ in
        _discoverServices(serviceUUIDs)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func discoverIncludedServices(_ serviceUUIDS: [CBUUID]?, for service: CBService) -> AnyPublisher<[CBService]?, Error> {
    didDiscoverIncludedServices
      .filterFirstValueOrThrow(where: { discoveredService in
        // ignore characteristics from services we're not interested in.
        guard discoveredService.uuid == service.uuid else { return false }
        // nil identifiers means we want to discover anything we can
        guard let identifiers = serviceUUIDS else { return true }
        // Only progress if the discovered service contains all the included services we are looking for.
        let neededUUIDs = Set(identifiers)
        let foundUUIDs = Set((discoveredService.includedServices ?? []).map(\.uuid))
        let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
        return allFound
      })
      .map(\.includedServices)
      .handleEvents(receiveSubscription: { [_discoverIncludedServices] _ in
        _discoverIncludedServices(serviceUUIDS, service)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) -> AnyPublisher<[CBCharacteristic], Error> {
    didDiscoverCharacteristics
      .filterFirstValueOrThrow(where: { discoveredService in
        // ignore characteristics from services we're not interested in.
        guard discoveredService.uuid == service.uuid else { return false }
        // nil identifiers means we want to discover anything we can
        guard let identifiers = characteristicUUIDs else { return true }
        // Only progress if the discovered service contains all the characteristics we are looking for.
        let neededUUIDs = Set(identifiers)
        let foundUUIDs = Set((discoveredService.characteristics ?? []).map(\.uuid))
        let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
        return allFound
      })
      .map({ $0.characteristics ?? [] })
      .handleEvents(receiveSubscription: { [_discoverCharacteristics] _ in
        _discoverCharacteristics(characteristicUUIDs, service)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func readValue(for characteristic: CBCharacteristic) -> AnyPublisher<Data?, Error> {
    didUpdateValueForCharacteristic
      .filterFirstValueOrThrow(where: {
        $0.uuid == characteristic.uuid
      })
      .map(\.value)
      .handleEvents(receiveSubscription: { [_readValueForCharacteristic] _ in
        _readValueForCharacteristic(characteristic)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func maximumWriteValueLength(for writeType: CBCharacteristicWriteType) -> Int {
    _maximumWriteValueLength(writeType)
  }

  public func writeValue(_ value: Data, for characteristic: CBCharacteristic, type writeType: CBCharacteristicWriteType) -> AnyPublisher<Void, Error> {
    if writeType == .withoutResponse {
      return writeValueWithoutResponse(value, for: characteristic)
    } else {
      return writeValueWithResponse(value, for: characteristic)
    }
  }

  private func writeValueWithoutResponse(_ value: Data, for characteristic: CBCharacteristic) -> AnyPublisher<Void, Error> {
    if characteristic.properties.contains(.writeWithoutResponse) {
      // Return an empty publisher here, since we never expect to receive a response.
      return Empty()
        .handleEvents(receiveSubscription: { [_writeValueForCharacteristic] _ in
          _writeValueForCharacteristic(value, characteristic, .withoutResponse)
        })
        .eraseToAnyPublisher()
    } else {
      // a response-less write against a characteristic that doesn't support it is silently ignored
      // by core bluetooth and never sends to the peripheral, so surface that case with an error here instead.
      return Fail(
        error: NSError(
          domain: CBATTErrorDomain,
          code: CBATTError.writeNotPermitted.rawValue,
          userInfo: [
            NSLocalizedDescriptionKey: "Writing without response is not permitted."
          ]
        )
      )
      .eraseToAnyPublisher()
    }
  }

  private func writeValueWithResponse(_ value: Data, for characteristic: CBCharacteristic) -> AnyPublisher<Void, Error> {
    didWriteValueForCharacteristic
     .filterFirstValueOrThrow(where: {
       $0.uuid == characteristic.uuid
     })
     .map { _ in }
     .handleEvents(receiveSubscription: { [_writeValueForCharacteristic] _ in
       _writeValueForCharacteristic(value, characteristic, .withResponse)
     })
     .shareCurrentValue()
     .eraseToAnyPublisher()
  }

  public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) -> AnyPublisher<Void, Error> {
    didUpdateNotificationState
      .filterFirstValueOrThrow(where: {
        $0.uuid == characteristic.uuid
      })
      .map { _ in }
      .handleEvents(receiveSubscription: { [_setNotifyValue] _ in
        _setNotifyValue(enabled, characteristic)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func discoverDescriptors(for characteristic: CBCharacteristic) -> AnyPublisher<[CBDescriptor]?, Error> {
    didDiscoverDescriptorsForCharacteristic
      .filterFirstValueOrThrow(where: {
        $0.uuid == characteristic.uuid
      })
      .map(\.descriptors)
      .handleEvents(receiveSubscription: { [_discoverDescriptors] _ in
        _discoverDescriptors(characteristic)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func readValue(for descriptor: CBDescriptor) -> AnyPublisher<Any?, Error> {
    didUpdateValueForDescriptor
      .filterFirstValueOrThrow(where: {
        $0.uuid == descriptor.uuid
      })
      .map(\.value)
      .handleEvents(receiveSubscription: { [_readValueForDescriptor] _ in
        _readValueForDescriptor(descriptor)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func writeValue(_ value: Data, for descriptor: CBDescriptor) -> AnyPublisher<Void, Error> {
    didWriteValueForDescriptor
      .filterFirstValueOrThrow(where: {
        $0.uuid == descriptor.uuid
      })
      .map { _ in }
      .handleEvents(receiveSubscription: { [_writeValueForDescriptor] _ in
        _writeValueForDescriptor(value, descriptor)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }

  public func openL2CAPChannel(_ psm: CBL2CAPPSM) -> AnyPublisher<L2CAPChannel, Error> {
    didOpenChannel
      .filterFirstValueOrThrow(where: { channel, error in
        return channel?.psm == psm || error != nil
      })
    // we won't get here unless channel is not nil, so we can safely force-unwrap
      .map { $0! }
      .handleEvents(receiveSubscription: { [_openL2CAPChannel] _ in
        _openL2CAPChannel(psm)
      })
      .shareCurrentValue()
      .eraseToAnyPublisher()
  }
}

extension Peripheral {
  public class Delegate: NSObject {
    var cbperipheral: CBPeripheral?

    public init(_ cbperipheral: CBPeripheral? = nil) {
      self.cbperipheral = cbperipheral
    }

    let nameUpdates:                             PassthroughSubject<String?, Never>                    = .init()
    let didInvalidateServices:                   PassthroughSubject<[CBService], Never>                = .init()
    let didReadRSSI:                             PassthroughSubject<Result<Double, Error>, Never>      = .init()
    let didDiscoverServices:                     PassthroughSubject<([CBService], Error?), Never>      = .init()
    let didDiscoverIncludedServices:             PassthroughSubject<(CBService, Error?), Never>        = .init()
    let didDiscoverCharacteristics:              PassthroughSubject<(CBService, Error?), Never>        = .init()
    let didUpdateValueForCharacteristic:         PassthroughSubject<(CBCharacteristic, Error?), Never> = .init()
    let didWriteValueForCharacteristic:          PassthroughSubject<(CBCharacteristic, Error?), Never> = .init()
    let didUpdateNotificationState:              PassthroughSubject<(CBCharacteristic, Error?), Never> = .init()
    let didDiscoverDescriptorsForCharacteristic: PassthroughSubject<(CBCharacteristic, Error?), Never> = .init()
    let didUpdateValueForDescriptor:             PassthroughSubject<(CBDescriptor, Error?), Never>     = .init()
    let didWriteValueForDescriptor:              PassthroughSubject<(CBDescriptor, Error?), Never>     = .init()
    let isReadyToSendWriteWithoutResponse:       PassthroughSubject<Void, Never>                       = .init()
    let didOpenChannel:                          PassthroughSubject<(L2CAPChannel?, Error?), Never>    = .init()
  }
}

extension Peripheral: Identifiable {
  public var id: UUID { identifier }
}

extension Peripheral: Equatable, Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}
