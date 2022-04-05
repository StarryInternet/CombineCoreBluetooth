import Foundation
import CoreBluetooth

extension Peripheral {
  public init(cbperipheral: CBPeripheral) {
    let delegate = cbperipheral.delegate as? Delegate ?? Delegate()
    cbperipheral.delegate = delegate
    self.init(
      rawValue: cbperipheral,
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

      _readRSSI: {
        return delegate
          .didReadRSSI
          .tryMap { result in
            try result.get().doubleValue
          }
          .first()
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.readRSSI()
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverServices: { (identifiers) in
        return delegate
          .didDiscoverServices
          .filterFirstValueOrThrow(where: { peripheral in
            // nil identifiers means we want to discover anything we can
            guard let identifiers = identifiers else { return true }
            // Only progress if the peripheral contains all the services we are looking for.
            let neededUUIDs = Set(identifiers)
            let foundUUIDs = Set((peripheral.services ?? []).map(\.uuid))
            let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
            return allFound
          })
          .map({ $0.services ?? [] })
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.discoverServices(identifiers)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverIncludedServices: { (identifiers, service) in
        return delegate
          .didDiscoverIncludedServices
          .filterFirstValueOrThrow(where: { discoveredService in
            // ignore characteristics from services we're not interested in.
            guard discoveredService.uuid == service.uuid else { return false }
            // nil identifiers means we want to discover anything we can
            guard let identifiers = identifiers else { return true }
            // Only progress if the discovered service contains all the included services we are looking for.
            let neededUUIDs = Set(identifiers)
            let foundUUIDs = Set((discoveredService.includedServices ?? []).map(\.uuid))
            let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
            return allFound
          })
          .map(\.includedServices)
          .handleEvents(receiveSubscription: { (subscription) in
            cbperipheral.discoverIncludedServices(identifiers, for: service)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverCharacteristics: { (identifiers, service) in
        return delegate
          .didDiscoverCharacteristics
          .filterFirstValueOrThrow(where: { discoveredService in
            // ignore characteristics from services we're not interested in.
            guard discoveredService.uuid == service.uuid else { return false }
            // nil identifiers means we want to discover anything we can
            guard let identifiers = identifiers else { return true }
            // Only progress if the discovered service contains all the characteristics we are looking for.
            let neededUUIDs = Set(identifiers)
            let foundUUIDs = Set((discoveredService.characteristics ?? []).map(\.uuid))
            let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
            return allFound
          })
          .map({ $0.characteristics ?? [] })
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.discoverCharacteristics(identifiers, for: service)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _readValueForCharacteristic: { (characteristic) in
        return delegate
          .didUpdateValueForCharacteristic
          .filterFirstValueOrThrow(where: {
            $0.uuid == characteristic.uuid
          })
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.readValue(for: characteristic)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _maximumWriteValueLength: { (writeType) -> Int in
        cbperipheral.maximumWriteValueLength(for: writeType)
      },

      _writeValueForCharacteristic: { (value, characteristic, writeType) in
        if writeType == .withoutResponse {
          // Return an empty publisher here, since we never expect to receive a response when writing using a .withoutResponse type. This will ignore errors we might get, but that will be resolved in a later version.
          return Empty()
            .handleEvents(receiveSubscription: { (sub) in
              cbperipheral.writeValue(value, for: characteristic, type: writeType)
            })
            .eraseToAnyPublisher()
        }

        return delegate
          .didWriteValueForCharacteristic
          .filterFirstValueOrThrow(where: {
            $0.uuid == characteristic.uuid
          })
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.writeValue(value, for: characteristic, type: writeType)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _setNotifyValue: { (enabled, characteristic) in
        return delegate
          .didUpdateNotificationState
          .filterFirstValueOrThrow(where: {
            $0.uuid == characteristic.uuid
          })
          .handleEvents(receiveSubscription: { _ in
            cbperipheral.setNotifyValue(enabled, for: characteristic)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverDescriptors: { (characteristic) in
        return delegate
          .didDiscoverDescriptorsForCharacteristic
          .filterFirstValueOrThrow(where: {
            $0.uuid == characteristic.uuid
          })
          .map(\.descriptors)
          .handleEvents(receiveSubscription: { _ in
            cbperipheral.discoverDescriptors(for: characteristic)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _readValueForDescriptor: { (descriptor) in
        return delegate
          .didUpdateValueForDescriptor
          .filterFirstValueOrThrow(where: {
            $0.uuid == descriptor.uuid
          })
          .handleEvents(receiveSubscription: { _ in
            cbperipheral.readValue(for: descriptor)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _writeValueForDescriptor: { (value, descriptor) in
        return delegate
          .didWriteValueForDescriptor
          .filterFirstValueOrThrow(where: {
            $0.uuid == descriptor.uuid
          })
          .handleEvents(receiveSubscription: { _ in
            cbperipheral.writeValue(value, for: descriptor)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _openL2CAPChannel: { (psm) in
        return delegate
          .didOpenChannel
          .filterFirstValueOrThrow(where: { channel, error in
            return channel?.psm == psm || error != nil
          })
        // we won't get here unless channel is not nil, so we can safely force-unwrap
          .map { $0! }
          .handleEvents(receiveSubscription: { _ in
            cbperipheral.openL2CAPChannel(psm)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _listenForUpdatesToCharacteristic: { characteristic in
        return delegate
          .didUpdateValueForCharacteristic
          .filter({ (readCharacteristic, error) -> Bool in
            return readCharacteristic.uuid == characteristic.uuid
          })
        // not limiting to `.first()` here as callers may want long-lived listening for value changes
          .tryMap {
            if let error = $1 { throw error }
            return $0
          }
          .eraseToAnyPublisher()
      },

      isReadyToSendWriteWithoutResponse: delegate.isReadyToSendWriteWithoutResponse,
      nameUpdates: delegate.nameUpdates,
      invalidatedServiceUpdates: delegate.didInvalidateServices
    )
  }
}

extension Peripheral {
  private class Delegate: NSObject, CBPeripheralDelegate {
    @PassthroughBacked var nameUpdates: AnyPublisher<String?, Never>
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
      _nameUpdates.send(peripheral.name)
    }

    @PassthroughBacked var didInvalidateServices: AnyPublisher<[CBService], Never>
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
      _didInvalidateServices.send(invalidatedServices)
    }

    @PassthroughBacked var didReadRSSI: AnyPublisher<Result<NSNumber, Error>, Never>
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
      if let error = error {
        _didReadRSSI.send(.failure(error))
      } else {
        _didReadRSSI.send(.success(RSSI))
      }
    }

    @PassthroughBacked var didDiscoverServices: AnyPublisher<(CBPeripheral, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
      _didDiscoverServices.send((peripheral, error))
    }

    @PassthroughBacked var didDiscoverIncludedServices: AnyPublisher<(CBService, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
      _didDiscoverIncludedServices.send((service, error))
    }

    @PassthroughBacked var didDiscoverCharacteristics: AnyPublisher<(CBService, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
      _didDiscoverCharacteristics.send((service, error))
    }

    @PassthroughBacked var didUpdateValueForCharacteristic: AnyPublisher<(CBCharacteristic, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
      _didUpdateValueForCharacteristic.send((characteristic, error))
    }

    @PassthroughBacked var didWriteValueForCharacteristic: AnyPublisher<(CBCharacteristic, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
      _didWriteValueForCharacteristic.send((characteristic, error))
    }

    @PassthroughBacked var didUpdateNotificationState: AnyPublisher<(CBCharacteristic, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
      _didUpdateNotificationState.send((characteristic, error))
    }

    @PassthroughBacked var didDiscoverDescriptorsForCharacteristic: AnyPublisher<(CBCharacteristic, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
      _didDiscoverDescriptorsForCharacteristic.send((characteristic, error))
    }

    @PassthroughBacked var didUpdateValueForDescriptor: AnyPublisher<(CBDescriptor, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
      _didUpdateValueForDescriptor.send((descriptor, error))
    }

    @PassthroughBacked var didWriteValueForDescriptor: AnyPublisher<(CBDescriptor, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
      _didWriteValueForDescriptor.send((descriptor, error))
    }

    @PassthroughBacked var isReadyToSendWriteWithoutResponse: AnyPublisher<Void, Never>
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
      _isReadyToSendWriteWithoutResponse.send()
    }

    @PassthroughBacked var didOpenChannel: AnyPublisher<(L2CAPChannel?, Error?), Never>
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
      _didOpenChannel.send((channel.map(L2CAPChannel.init(channel:)), error))
    }
  }
}
