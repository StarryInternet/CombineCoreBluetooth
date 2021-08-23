import Foundation

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
        #if os(macOS)
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
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.readRSSI()
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverServices: { (identifiers) in
        return delegate
          .didDiscoverServices
          .filter({ (peripheral, error) in
            guard let identifiers = identifiers else { return true } // nil identifiers means we want to discover anything we can
            let neededUUIDs = Set(identifiers)
            let foundUUIDs = Set((peripheral.services ?? []).map(\.uuid))
            let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
            return allFound
          })
          .prefix(1)
          .tryMap({ (peripheral, error) in
            if let error = error {
              throw error
            }
            return peripheral.services ?? []
          })
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.discoverServices(identifiers)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverIncludedServices: { (identifiers, service) in
        return delegate
          .didDiscoverIncludedServices
          .filter({ (discoveredService, error) in
            guard discoveredService.uuid == service.uuid else { return false }
            guard let identifiers = identifiers else { return true }
            let neededUUIDs = Set(identifiers)
            let foundUUIDs = Set((discoveredService.includedServices ?? []).map(\.uuid))
            let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
            return allFound
          })
          .prefix(1)
          .tryMap({ (discoveredService, error) in
            if let error = error {
              throw error
            }
            return discoveredService.includedServices
          })
          .handleEvents(receiveSubscription: { (subscription) in
            cbperipheral.discoverIncludedServices(identifiers, for: service)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverCharacteristics: { (identifiers, service) in
        return delegate
          .didDiscoverCharacteristics
          .filter({ (discoveredService, error) -> Bool in
            guard discoveredService.uuid == service.uuid else { return false } // ignore characteristics from services we're not interested in.
            guard let identifiers = identifiers else { return true } // nil identifiers means we want to discover anything we can
            // only continue if all identifiers we're trying to discover are fully discovered.
            let neededUUIDs = Set(identifiers)
            let foundUUIDs = Set((discoveredService.characteristics ?? []).map(\.uuid))
            let allFound = foundUUIDs.isSuperset(of: neededUUIDs)
            return allFound
          })
          .tryMap({ (discoveredService, error) in
            if let error = error {
              throw error
            }
            return discoveredService.characteristics ?? []
          })
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.discoverCharacteristics(identifiers, for: service)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _readValueForCharacteristic: { (characteristic) in
        return delegate
          .didUpdateValueForCharacteristic
          .filter({ (readCharacteristic, error) -> Bool in
            return readCharacteristic.uuid == characteristic.uuid
          })
          .tryMap({ (characteristic, error) in
            if let error = error {
              throw error
            }
            return characteristic
          })
          .prefix(1)
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
        return delegate
          .didWriteValueForCharacteristic
          .filter({ (writeCharacteristic, error) in
            return writeCharacteristic.uuid == characteristic.uuid
          })
          .tryMap({ (characteristic, error) in
            if let error = error {
              throw error
            }
            return characteristic
          })
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.writeValue(value, for: characteristic, type: writeType)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _setNotifyValue: { (enabled, characteristic) in
        // Unlike elsewhere in this file, we fire this off immediately, since we may not care about the response if we're toggling it off.
        cbperipheral.setNotifyValue(enabled, for: characteristic)
        return delegate
          .didUpdateNotificationState
          .filter({ (notifyCharacteristic, error) in
            return notifyCharacteristic.uuid == characteristic.uuid
          })
          .tryMap({ (characteristic, error) -> CBCharacteristic in
            if let error = error {
              throw error
            }
            return characteristic
          })
          .prefix(1)
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _discoverDescriptors: { (characteristic) in
        return delegate
          .didDiscoverDescriptorsForCharacteristic
          .filter({ (discoverCharacteristic, error) -> Bool in
            return discoverCharacteristic.uuid == characteristic.uuid
          })
          .tryMap({ (characteristic, error) in
            if let error = error {
              throw error
            }
            return characteristic.descriptors
          })
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.discoverDescriptors(for: characteristic)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _readValueForDescriptor: { (descriptor) in
        return delegate
          .didUpdateValueForDescriptor
          .filter({ (readDescriptor, error) -> Bool in
            return readDescriptor.uuid == descriptor.uuid
          })
          .tryMap({ (readDescriptor, error) in
            if let error = error {
              throw error
            }
            return readDescriptor
          })
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.readValue(for: descriptor)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _writeValueForDescriptor: { (value, descriptor) in
        return delegate
          .didWriteValueForDescriptor
          .filter({ (writeDescriptor, error) -> Bool in
            return writeDescriptor.uuid == descriptor.uuid
          })
          .tryMap({ (writeDescriptor, error) in
            if let error = error {
              throw error
            }
            return writeDescriptor
          })
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
            cbperipheral.writeValue(value, for: descriptor)
          })
          .shareCurrentValue()
          .eraseToAnyPublisher()
      },

      _openL2CAPChannel: { (psm) in
        return delegate
          .didOpenChannel
          .filter({ (channel, error) in
            return channel?.psm == psm || error != nil
          }).tryMap({ (channel, error) in
            if let error = error {
              throw error
            }
            return channel! // we won't get here unless channel isn't nil, so we can safely unwrap
          })
          .prefix(1)
          .handleEvents(receiveSubscription: { (sub) in
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
          .tryMap({ (characteristic, error) in
            if let error = error {
              throw error
            }
            return characteristic
          })
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
