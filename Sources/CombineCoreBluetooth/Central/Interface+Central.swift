import Foundation

public struct Central {
  let rawValue: CBCentral?

  public let identifier: UUID

  let _maximumUpdateValueLength: () -> Int

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
