import Foundation
@preconcurrency import CoreBluetooth

public enum PeripheralError: Error, Equatable {
  case serviceNotFound(CBUUID)
  case characteristicNotFound(CBUUID)
  case descriptorNotFound(CBUUID, onCharacteristic: CBUUID)
}
