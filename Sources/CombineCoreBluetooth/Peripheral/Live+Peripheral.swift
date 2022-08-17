import Foundation
import CoreBluetooth

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

      _readRSSI: cbperipheral.readRSSI,
      _discoverServices: cbperipheral.discoverServices,
      _discoverIncludedServices: cbperipheral.discoverIncludedServices(_:for:),
      _discoverCharacteristics: cbperipheral.discoverCharacteristics(_:for:),
      _readValueForCharacteristic: cbperipheral.readValue(for:),
      _maximumWriteValueLength: cbperipheral.maximumWriteValueLength(for:),
      _writeValueForCharacteristic: cbperipheral.writeValue(_:for:type:),
      _setNotifyValue: cbperipheral.setNotifyValue(_:for:),
      _discoverDescriptors: cbperipheral.discoverDescriptors(for:),
      _readValueForDescriptor: cbperipheral.readValue(for:),
      _writeValueForDescriptor: cbperipheral.writeValue(_:for:),
      _openL2CAPChannel: cbperipheral.openL2CAPChannel(_:),

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
  public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    nameUpdates.send(peripheral.name)
  }

  public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
    didInvalidateServices.send(invalidatedServices)
  }

  public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    if let error = error {
      didReadRSSI.send(.failure(error))
    } else {
      didReadRSSI.send(.success(RSSI.doubleValue))
    }
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    didDiscoverServices.send((peripheral.services ?? [], error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    didDiscoverIncludedServices.send((service, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    didDiscoverCharacteristics.send((service, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    didUpdateValueForCharacteristic.send((characteristic, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    didWriteValueForCharacteristic.send((characteristic, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    didUpdateNotificationState.send((characteristic, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    didDiscoverDescriptorsForCharacteristic.send((characteristic, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    didUpdateValueForDescriptor.send((descriptor, error))
  }

  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    didWriteValueForDescriptor.send((descriptor, error))
  }

  public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    isReadyToSendWriteWithoutResponse.send()
  }

  public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
    didOpenChannel.send((channel.map(L2CAPChannel.init(channel:)), error))
  }
}
