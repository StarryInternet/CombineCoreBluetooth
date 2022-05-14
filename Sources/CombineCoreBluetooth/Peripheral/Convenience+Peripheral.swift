import Foundation
import CoreBluetooth

public enum PeripheralError: Error, Equatable {
  case serviceNotFound(CBUUID)
  case characteristicNotFound(CBUUID)
}

extension Peripheral {
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
    delegate
      .didUpdateValueForCharacteristic
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
