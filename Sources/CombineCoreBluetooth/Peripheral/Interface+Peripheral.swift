import Foundation

/// The `CombineCoreBluetooth` wrapper around `CBPeripheral`.
public struct Peripheral {
  let rawValue: CBPeripheral?

  var _name: () -> String?
  var _identifier: () -> UUID
  var _state: () -> CBPeripheralState
  var _services: () -> [CBService]?
  var _canSendWriteWithoutResponse: () -> Bool

  @available(macOS, unavailable)
  var _ancsAuthorized: () -> Bool

  var _readRSSI: () -> AnyPublisher<Double, Error>
  var _discoverServices: (_ serviceUUIDs: [CBUUID]?) -> AnyPublisher<[CBService], Error>
  var _discoverIncludedServices: (_ includedServiceUUIDs: [CBUUID]?, _ service: CBService) -> AnyPublisher<[CBService]?, Error>
  var _discoverCharacteristics: (_ characteristicUUIDs: [CBUUID]?, _ service: CBService) -> AnyPublisher<[CBCharacteristic], Error>
  var _readValueForCharacteristic: (_ characteristic: CBCharacteristic) -> AnyPublisher<Data?, Error>
  var _maximumWriteValueLength: (_ type: CBCharacteristicWriteType) -> Int
  var _writeValueForCharacteristic: (_ data: Data, _ characteristic: CBCharacteristic, _ type: CBCharacteristicWriteType) -> AnyPublisher<Void, Error>
  var _setNotifyValue: (_ enabled: Bool, _ characteristic: CBCharacteristic) -> AnyPublisher<Void, Error>
  var _discoverDescriptors: (_ characteristic: CBCharacteristic) -> AnyPublisher<[CBDescriptor]?, Error>
  var _readValueForDescriptor: (_ descriptor: CBDescriptor) -> AnyPublisher<Any?, Error>
  var _writeValueForDescriptor: (_ data: Data, _ descriptor: CBDescriptor) -> AnyPublisher<Void, Error>
  var _openL2CAPChannel: (_ PSM: CBL2CAPPSM) -> AnyPublisher<L2CAPChannel, Error>
  var _listenForUpdatesToCharacteristic: (_ characteristic: CBCharacteristic) -> AnyPublisher<Data?, Error>

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
    _readRSSI()
  }

  public func discoverServices(_ serviceUUIDs: [CBUUID]?) -> AnyPublisher<[CBService], Error> {
    _discoverServices(serviceUUIDs)
  }

  public func discoverIncludedServices(_ serviceUUIDS: [CBUUID]?, for service: CBService) -> AnyPublisher<[CBService]?, Error> {
    _discoverIncludedServices(serviceUUIDS, service)
  }

  public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) -> AnyPublisher<[CBCharacteristic], Error> {
    _discoverCharacteristics(characteristicUUIDs, service)
  }

  public func readValue(for characteristic: CBCharacteristic) -> AnyPublisher<Data?, Error> {
    _readValueForCharacteristic(characteristic)
  }

  public func maximumWriteValueLength(for writeType: CBCharacteristicWriteType) -> Int {
    _maximumWriteValueLength(writeType)
  }

  public func writeValue(_ value: Data, for characteristic: CBCharacteristic, type writeType: CBCharacteristicWriteType) -> AnyPublisher<Void, Error> {
    _writeValueForCharacteristic(value, characteristic, writeType)
  }

  public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) -> AnyPublisher<Void, Error> {
    _setNotifyValue(enabled, characteristic)
  }

  public func discoverDescriptors(for characteristic: CBCharacteristic) -> AnyPublisher<[CBDescriptor]?, Error> {
    _discoverDescriptors(characteristic)
  }

  public func readValue(for descriptor: CBDescriptor) -> AnyPublisher<Any?, Error> {
    _readValueForDescriptor(descriptor)
  }

  public func writeValue(_ value: Data, for descriptor: CBDescriptor) -> AnyPublisher<Void, Error> {
    _writeValueForDescriptor(value, descriptor)
  }

  public func openL2CAPChannel(_ psm: CBL2CAPPSM) -> AnyPublisher<L2CAPChannel, Error> {
    _openL2CAPChannel(psm)
  }

  public func listenForUpdates(on characteristic: CBCharacteristic) -> AnyPublisher<Data?, Error> {
    _listenForUpdatesToCharacteristic(characteristic)
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
