import Foundation

public enum CentralManagerError: Error, Equatable, Sendable {
  /// Thrown if there's a failure during connection to a peripheral, but there's no error information
  case unknownConnectionFailure
}

extension CentralManagerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .unknownConnectionFailure:
      return "Unknown failure connecting to the peripheral."
    }
  }
}
