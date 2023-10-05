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

      didReadRSSI: delegate.didReadRSSI.eraseToAnyPublisher(),
      didDiscoverServices: delegate.didDiscoverServices.eraseToAnyPublisher(),
      didDiscoverIncludedServices: delegate.didDiscoverIncludedServices.eraseToAnyPublisher(),
      didDiscoverCharacteristics: delegate.didDiscoverCharacteristics.eraseToAnyPublisher(),
      didUpdateValueForCharacteristic: delegate.didUpdateValueForCharacteristic.eraseToAnyPublisher(),
      didWriteValueForCharacteristic: delegate.didWriteValueForCharacteristic.eraseToAnyPublisher(),
      didUpdateNotificationState: delegate.didUpdateNotificationState.eraseToAnyPublisher(),
      didDiscoverDescriptorsForCharacteristic: delegate.didDiscoverDescriptorsForCharacteristic.eraseToAnyPublisher(),
      didUpdateValueForDescriptor: delegate.didUpdateValueForDescriptor.eraseToAnyPublisher(),
      didWriteValueForDescriptor: delegate.didWriteValueForDescriptor.eraseToAnyPublisher(),
      didOpenChannel: delegate.didOpenChannel.eraseToAnyPublisher(),

      isReadyToSendWriteWithoutResponse: delegate.isReadyToSendWriteWithoutResponse.eraseToAnyPublisher(),
      nameUpdates: delegate.nameUpdates.eraseToAnyPublisher(),
      invalidatedServiceUpdates: delegate.didInvalidateServices.eraseToAnyPublisher()
    )
  }
}

extension Peripheral.Delegate: CBPeripheralDelegate {
  func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    nameUpdates.send(peripheral.name)
  }

  func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    didInvalidateServices.send(invalidatedServices)
  }

  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    if let error = error {
      didReadRSSI.send(.failure(error))
    } else {
      didReadRSSI.send(.success(RSSI.doubleValue))
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    didDiscoverServices.send((peripheral.services ?? [], error))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    didDiscoverIncludedServices.send((service, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    didDiscoverCharacteristics.send((service, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    didUpdateValueForCharacteristic.send((characteristic, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    didWriteValueForCharacteristic.send((characteristic, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    didUpdateNotificationState.send((characteristic, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    didDiscoverDescriptorsForCharacteristic.send((characteristic, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    didUpdateValueForDescriptor.send((descriptor, error))
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    didWriteValueForDescriptor.send((descriptor, error))
  }

  func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    isReadyToSendWriteWithoutResponse.send()
  }

  func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
    didOpenChannel.send((channel.map(L2CAPChannel.init(channel:)), error))
  }
}
