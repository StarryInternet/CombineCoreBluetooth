import Foundation

public enum _Internal {
  public static func _unimplemented<Output>(
    _ function: StaticString, file: StaticString = #file, line: UInt = #line
  ) -> @Sendable () -> Output {
    return {
      fatalError(
        """
        `\(function)` was called but is not implemented. Be sure to provide an implementation for
        this endpoint when creating the mock.
        """,
        file: file,
        line: line
      )
    }
  }

  public static func _unimplemented<Input, Output>(
    _ function: StaticString, file: StaticString = #file, line: UInt = #line
  ) -> @Sendable (Input) -> Output {
    return { _ in
      fatalError(
        """
        `\(function)` was called but is not implemented. Be sure to provide an implementation for
        this endpoint when creating the mock.
        """,
        file: file,
        line: line
      )
    }
  }

  public static func _unimplemented<Input1, Input2, Output>(
    _ function: StaticString, file: StaticString = #file, line: UInt = #line
  ) -> @Sendable (Input1, Input2) -> Output {
    return { _, _ in
      fatalError(
        """
        `\(function)` was called but is not implemented. Be sure to provide an implementation for
        this endpoint when creating the mock.
        """,
        file: file,
        line: line
      )
    }
  }

  public static func _unimplemented<Input1, Input2, Input3, Output>(
    _ function: StaticString, file: StaticString = #file, line: UInt = #line
  ) -> @Sendable (Input1, Input2, Input3) -> Output {
    return { _, _, _ in
      fatalError(
        """
        `\(function)` was called but is not implemented. Be sure to provide an implementation for
        this endpoint when creating the mock.
        """,
        file: file,
        line: line
      )
    }
  }

  public static func _unimplemented<Output, Failure>(
    _ publisher: StaticString, file: StaticString = #file, line: UInt = #line
  ) -> AnyPublisher<Output, Failure> {
    Deferred<AnyPublisher<Output, Failure>> {
      fatalError(
        """
        `\(publisher)` was subscribed to but is not implemented. Be sure to provide an implementation for
        this publisher when creating the mock.
        """,
        file: file,
        line: line
      )
    }.eraseToAnyPublisher()
  }
}
