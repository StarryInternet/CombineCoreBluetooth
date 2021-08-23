import Foundation

extension Peripheral {
  public static func unimplemented(
    name: String? = nil,
    identifier: UUID = .init(),
    state: @escaping () -> CBPeripheralState = Internal._unimplemented("state"),
    services: @escaping () -> [CBService]? = Internal._unimplemented("services"),
    canSendWriteWithoutResponse: @escaping () -> Bool = Internal._unimplemented("canSendWriteWithoutResponse"),
    ancsAuthorized: @escaping () -> Bool = Internal._unimplemented("ancsAuthorized"),
    readRSSI: @escaping () -> AnyPublisher<Double, Error> = Internal._unimplemented("readRSSI"),
    discoverServices: @escaping ([CBUUID]?) -> AnyPublisher<[CBService], Error> = Internal._unimplemented("discoverServices") ,
    discoverIncludedServices: @escaping ([CBUUID]?, CBService) -> AnyPublisher<[CBService]?, Error> = Internal._unimplemented("discoverIncludedServices"),
    discoverCharacteristics: @escaping ([CBUUID]?, CBService) -> AnyPublisher<[CBCharacteristic], Error> = Internal._unimplemented("discoverCharacteristics"),
    readValueForCharacteristic: @escaping (CBCharacteristic) -> AnyPublisher<CBCharacteristic, Error> = Internal._unimplemented("readValueForCharacteristic"),
    maximumWriteValueLength: @escaping (CBCharacteristicWriteType) -> Int = Internal._unimplemented("maximumWriteValueLength"),
    writeValueForCharacteristic: @escaping (Data, CBCharacteristic, CBCharacteristicWriteType) -> AnyPublisher<CBCharacteristic, Error> = Internal._unimplemented("writeValueForCharacteristic"),
    setNotifyValue: @escaping (Bool, CBCharacteristic) -> AnyPublisher<CBCharacteristic, Error> = Internal._unimplemented("setNotifyValue"),
    discoverDescriptors: @escaping (CBCharacteristic) -> AnyPublisher<[CBDescriptor]?, Error> = Internal._unimplemented("discoverDescriptors"),
    readValueForDescriptor: @escaping (CBDescriptor) -> AnyPublisher<CBDescriptor, Error> = Internal._unimplemented("readValueForDescriptor"),
    writeValueForDescriptor: @escaping (Data, CBDescriptor) -> AnyPublisher<CBDescriptor, Error> = Internal._unimplemented("writeValueForDescriptor"),
    openL2CAPChannel: @escaping (CBL2CAPPSM) -> AnyPublisher<L2CAPChannel, Error> = Internal._unimplemented("openL2CAPChannel"),
    listenForUpdatesToCharacteristic: @escaping (CBCharacteristic) -> AnyPublisher<CBCharacteristic, Error> = Internal._unimplemented("listenForUpdatesToCharacteristic"),
    isReadyToSendWriteWithoutResponse: AnyPublisher<Void, Never> = Internal._unimplemented("isReadyToSendWriteWithoutResponse"),
    nameUpdates: AnyPublisher<String?, Never> = Internal._unimplemented("nameUpdates"),
    invalidatedServiceUpdates: AnyPublisher<[CBService], Never> = Internal._unimplemented("invalidatedServiceUpdates")
  ) -> Peripheral {
    Peripheral(
      rawValue: nil,
      _name: { name },
      _identifier: { identifier },
      _state: state,
      _services: services,
      _canSendWriteWithoutResponse: canSendWriteWithoutResponse,
      _ancsAuthorized: ancsAuthorized,
      _readRSSI: readRSSI,
      _discoverServices: discoverServices,
      _discoverIncludedServices: discoverIncludedServices,
      _discoverCharacteristics: discoverCharacteristics,
      _readValueForCharacteristic: readValueForCharacteristic,
      _maximumWriteValueLength: maximumWriteValueLength,
      _writeValueForCharacteristic: writeValueForCharacteristic,
      _setNotifyValue: setNotifyValue,
      _discoverDescriptors: discoverDescriptors,
      _readValueForDescriptor: readValueForDescriptor,
      _writeValueForDescriptor: writeValueForDescriptor,
      _openL2CAPChannel: openL2CAPChannel,
      _listenForUpdatesToCharacteristic: listenForUpdatesToCharacteristic,
      isReadyToSendWriteWithoutResponse: isReadyToSendWriteWithoutResponse,
      nameUpdates: nameUpdates,
      invalidatedServiceUpdates: invalidatedServiceUpdates
    )
  }
}
