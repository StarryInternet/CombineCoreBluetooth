import Foundation
import CoreBluetooth

public struct ATTRequest: Hashable, Identifiable {
  public let id = UUID()
  let rawValue: CBATTRequest?

  public let central: Central
  public let characteristic: CBCharacteristic
  public let offset: Int
  public var value: Data? {
    didSet {
      rawValue?.value = value
    }
  }
    
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension ATTRequest {
  init(cbattrequest: CBATTRequest) {
    self.init(
      rawValue: cbattrequest,
      central: .init(cbcentral: cbattrequest.central),
      characteristic: cbattrequest.characteristic,
      offset: cbattrequest.offset,
      value: cbattrequest.value
    )
  }
}

extension ATTRequest {
  public init(
    central: Central,
    characteristic: CBCharacteristic,
    offset: Int,
    value: Data?
  ) {
    self.init(
      rawValue: nil,
      central: central,
      characteristic: characteristic,
      offset: offset,
      value: value
    )
  }
}
