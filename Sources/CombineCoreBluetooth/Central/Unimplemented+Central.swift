import Foundation

extension Central {
  public static func unimplemented(
    identifier: UUID,
    maximumUpdateValueLength: @escaping () -> Int = _Internal._unimplemented("maximumUpdateValueLength")
  ) -> Self {
    return .init(
      rawValue: nil,
      identifier: identifier,
      _maximumUpdateValueLength: maximumUpdateValueLength
    )
  }
}
