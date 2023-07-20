import Foundation

public enum PeripheralManagerError: Error, Equatable {
  /// Thrown if there's a failure during connection to a peripheral
  case failedToUpdateCharacteristic(CBUUID)
}
