import Foundation
@preconcurrency import CoreBluetooth

extension Peripheral {
  public init(cbperipheral: CBPeripheral) {
    let delegate = cbperipheral.delegate as? Delegate ?? Delegate()
    cbperipheral.delegate = delegate

    self.init(
      rawValue: cbperipheral,
      delegate: delegate,
      _name: { cbperipheral.name },
      _identifier: { cbperipheral.identifier },
      _state: { cbperipheral.state },
      _services: { cbperipheral.services },
      _canSendWriteWithoutResponse: { cbperipheral.canSendWriteWithoutResponse },
      _ancsAuthorized: {
#if os(macOS) && !targetEnvironment(macCatalyst)
        fatalError("This method is not callable on macOS")
#else
        return cbperipheral.ancsAuthorized
#endif
      },

      _readRSSI: { cbperipheral.readRSSI() },
      _discoverServices: { cbperipheral.discoverServices($0) },
      _discoverIncludedServices: { cbperipheral.discoverIncludedServices($0, for: $1) },
      _discoverCharacteristics: { cbperipheral.discoverCharacteristics($0, for: $1) },
      _readValueForCharacteristic: { cbperipheral.readValue(for: $0) },
      _maximumWriteValueLength: { cbperipheral.maximumWriteValueLength(for: $0) },
      _writeValueForCharacteristic: { cbperipheral.writeValue($0, for: $1, type: $2) },
      _setNotifyValue: { cbperipheral.setNotifyValue($0, for: $1) },
      _discoverDescriptors: { cbperipheral.discoverDescriptors(for: $0) },
      _readValueForDescriptor: { cbperipheral.readValue(for: $0) },
      _writeValueForDescriptor: { cbperipheral.writeValue($0, for: $1) },
      _openL2CAPChannel: { cbperipheral.openL2CAPChannel($0) },

      didReadRSSI: delegate.actionSubject.compactMap { $0.didReadRSSI }.eraseToAnyPublisher(),
      didDiscoverServices: delegate.actionSubject.compactMap { $0.didDiscoverServices }.eraseToAnyPublisher(),
      didDiscoverIncludedServices: delegate.actionSubject.compactMap { $0.didDiscoverIncludedServices }.eraseToAnyPublisher(),
      didDiscoverCharacteristics: delegate.actionSubject.compactMap { $0.didDiscoverCharacteristics }.eraseToAnyPublisher(),
      didUpdateValueForCharacteristic: delegate.actionSubject.compactMap { $0.didUpdateValueForCharacteristic }.eraseToAnyPublisher(),
      didWriteValueForCharacteristic: delegate.actionSubject.compactMap { $0.didWriteValueForCharacteristic }.eraseToAnyPublisher(),
      didUpdateNotificationState: delegate.actionSubject.compactMap { $0.didUpdateNotificationState }.eraseToAnyPublisher(),
      didDiscoverDescriptorsForCharacteristic: delegate.actionSubject.compactMap { $0.didDiscoverDescriptorsForCharacteristic }.eraseToAnyPublisher(),
      didUpdateValueForDescriptor: delegate.actionSubject.compactMap { $0.didUpdateValueForDescriptor }.eraseToAnyPublisher(),
      didWriteValueForDescriptor: delegate.actionSubject.compactMap { $0.didWriteValueForDescriptor }.eraseToAnyPublisher(),
      didOpenChannel: delegate.actionSubject.compactMap { $0.didOpenChannel }.eraseToAnyPublisher(),

      isReadyToSendWriteWithoutResponse: delegate.actionSubject.compactMap { $0.isReadyToSendWriteWithoutResponse }.eraseToAnyPublisher(),
      nameUpdates: delegate.actionSubject.compactMap { $0.nameUpdates }.eraseToAnyPublisher(),
      invalidatedServiceUpdates: delegate.actionSubject.compactMap { $0.didInvalidateServices }.eraseToAnyPublisher()
    )
  }
}

extension Peripheral.Delegate: CBPeripheralDelegate {
  func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    actionSubject.send(.nameUpdates(peripheral.name))
  }

  func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    actionSubject.send(.didInvalidateServices(invalidatedServices))
  }

  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    if let error = error {
      actionSubject.send(.didReadRSSI(.failure(error)))
    } else {
      actionSubject.send(.didReadRSSI(.success(RSSI.doubleValue)))
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    actionSubject.send(.didDiscoverServices((peripheral.services ?? [], error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    actionSubject.send(.didDiscoverIncludedServices((service, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    actionSubject.send(.didDiscoverCharacteristics((service, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    actionSubject.send(.didUpdateValueForCharacteristic((characteristic, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    actionSubject.send(.didWriteValueForCharacteristic((characteristic, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    actionSubject.send(.didUpdateNotificationState((characteristic, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    actionSubject.send(.didDiscoverDescriptorsForCharacteristic((characteristic, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    actionSubject.send(.didUpdateValueForDescriptor((descriptor, error)))
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    actionSubject.send(.didWriteValueForDescriptor((descriptor, error)))
  }

  func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    actionSubject.send(.isReadyToSendWriteWithoutResponse)
  }

  func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
    actionSubject.send(.didOpenChannel((channel.map(L2CAPChannel.init(channel:)), error)))
  }
}
