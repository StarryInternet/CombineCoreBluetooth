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

  // MARK: - Implementations

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

  // MARK: - Convenience methods

  /// Discovers the service with the given service UUID, then discovers characteristics with the given UUIDs and returns those.
  /// - Parameters:
  ///   - characteristicUUIDs: The UUIDs of the characteristics you want to discover.
  ///   - serviceUUID: The service to discover that contain the characteristics you need.
  /// - Returns: A publisher of the desired characteristics
  public func discoverCharacteristics(withUUIDs characteristicUUIDs: [CBUUID], inServiceWithUUID serviceUUID: CBUUID) -> AnyPublisher<[CBCharacteristic], Error> {
    discoverServices([serviceUUID])
    // discover all the characteristics we need
      .flatMap { (services) -> AnyPublisher<[CBCharacteristic], Error> in
        // safe to force unwrap, since `discoverServices` guarantees that if you give it a non-nil array, it will only publish a value
        // if the requested services are all present
        guard let service = services.first(where: { $0.uuid == serviceUUID }) else {
          return Fail(error: PeripheralError.serviceNotFound(serviceUUID)).eraseToAnyPublisher()
        }
        return discoverCharacteristics(characteristicUUIDs, for: service)
      }
      .first()
      .eraseToAnyPublisher()
  }

  /// Discovers the service with the given service UUID, then discovers the characteristic with the given UUID and returns that.
  /// - Parameters:
  ///   - characteristicUUIDs: The UUID of the characteristic you want to discover.
  ///   - serviceUUID: The service to discover that contain the characteristics you need.
  /// - Returns: A publisher of the desired characteristic
  public func discoverCharacteristic(withUUID characteristicUUID: CBUUID, inServiceWithUUID serviceUUID: CBUUID) -> AnyPublisher<CBCharacteristic, Error> {
    discoverCharacteristics(withUUIDs: [characteristicUUID], inServiceWithUUID: serviceUUID)
      .tryMap { characteristics in
        // assume core bluetooth won't send us a characteristic list without the characteristic we expect
        guard let characteristic = characteristics.first(where: { characteristic in characteristic.uuid == characteristicUUID }) else {
          throw PeripheralError.characteristicNotFound(characteristicUUID)
        }
        return characteristic
      }
      .eraseToAnyPublisher()
  }

  /// Reads the value in the characteristic with the given UUID from the service with the given UUID.
  /// - Parameters:
  ///   - characteristicUUID: The UUID of the characteristic to read from.
  ///   - serviceUUID: The UUID of the service the characteristic is a part of.
  /// - Returns: A publisher that sends the value that is read from the desired characteristic.
  public func readValue(forCharacteristic characteristicUUID: CBUUID, inService serviceUUID: CBUUID) -> AnyPublisher<Data?, Error> {
    discoverCharacteristic(withUUID: characteristicUUID, inServiceWithUUID: serviceUUID)
      .flatMap { characteristic in
        self.readValue(for: characteristic)
      }
      .eraseToAnyPublisher()
  }

  /// Writes the given data to the characteristic with the given UUID in the service in the given UUID
  /// - Parameters:
  ///   - value: The data to write
  ///   - writeType: How to write the data
  ///   - characteristicUUID: the id of the characteristic
  ///   - serviceUUID: the service the characteristic exists within
  /// - Returns: A publisher that finishes immediately with no output if the write type is without response, or with a `Void` value if the the write type is with response, when we are told that the write completed. Completes with an error if the write fails, if the write type is unsupported.
  public func writeValue(_ value: Data, writeType: CBCharacteristicWriteType, forCharacteristic characteristicUUID: CBUUID, inService serviceUUID: CBUUID) -> AnyPublisher<Void, Error> {
    discoverCharacteristic(withUUID: characteristicUUID, inServiceWithUUID: serviceUUID)
      .flatMap { characteristic in
        self.writeValue(value, for: characteristic, type: writeType)
      }
      .eraseToAnyPublisher()
  }

  /// Returns a long-lived publisher that receives all value updates for the given characteristic. Allows for many listeners to be updated for a single read, or for indications/notifications of a characteristic.
  /// - Parameter characteristic: The characteristic to listen to for updates.
  /// - Returns: A publisher that will listen to updates to the given characteristic. Continues indefinitely, unless an error is encountered.
  public func listenForUpdates(on characteristic: CBCharacteristic) -> AnyPublisher<Data?, Error> {
    didUpdateValueForCharacteristic
    // not limiting to `.first()` here as callers may want long-lived listening for value changes
      .filter({ (readCharacteristic, error) -> Bool in
        return readCharacteristic.uuid == characteristic.uuid
      })
      .tryMap {
        if let error = $1 { throw error }
        return $0.value
      }
      .eraseToAnyPublisher()
  }
}

// MARK: -

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
