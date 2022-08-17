import Foundation

public enum CentralManagerError: Error, Equatable {
  /// Thrown if there's a failure during connection to a peripheral
  case failedToConnect(NSError?)
}

extension CentralManagerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .failedToConnect(error):
      return error?.localizedDescription
    }
  }

  public var failureReason: String? {
    switch self {
    case let .failedToConnect(error):
      return error?.localizedFailureReason
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case let .failedToConnect(error):
      return error?.localizedRecoverySuggestion
    }
  }

  public var helpAnchor: String? {
    switch self {
    case let .failedToConnect(error):
      return error?.helpAnchor
    }
  }
}
