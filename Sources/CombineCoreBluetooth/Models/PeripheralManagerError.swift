import Foundation
@preconcurrency import CoreBluetooth

public enum PeripheralManagerError: Error, Equatable, Sendable {
  /// Thrown if there's a failure during updating subscribed centrals of a characteristic's new value.
  case failedToUpdateCharacteristic(CBUUID)
}
