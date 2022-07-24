import Foundation
import CoreBluetooth

public enum PeripheralError: Error, Equatable {
  case serviceNotFound(CBUUID)
  case characteristicNotFound(CBUUID)
}
