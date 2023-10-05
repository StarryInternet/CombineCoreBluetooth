import Foundation
@preconcurrency import CoreBluetooth

public struct Central: Sendable {
  let rawValue: CBCentral?

  public let identifier: UUID

  public var _maximumUpdateValueLength: @Sendable () -> Int

  public var maximumUpdateValueLength: Int {
    _maximumUpdateValueLength()
  }
}

extension Central: Identifiable {
  public var id: UUID {
    identifier
  }
}

extension Central: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }
}

extension Central: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}
