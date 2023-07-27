import Foundation

public enum PeripheralManagerError: Error, Equatable {
  /// Thrown if there's a failure during updating subscribed centrals of a characteristic's new value.
  case failedToUpdateCharacteristic(CBUUID)
}
