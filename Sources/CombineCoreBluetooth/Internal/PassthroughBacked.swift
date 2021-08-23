import Foundation
import Combine

/// Property Wrapper that wraps an `AnyPublisher`, which is backed by a `PassthroughSubject`. This is to make it possible  to easily expose just a publisher to consumers of a type,
/// without also exposing the `PassthroughSubject` to consumers, effectively allowing for public reads and private writes of a publisher.
@propertyWrapper
struct PassthroughBacked<Output> {

  private var subject: PassthroughSubject<Output, Never>
  init() {
    subject = PassthroughSubject<Output, Never>()
  }

  var wrappedValue: AnyPublisher<Output, Never> {
    subject.eraseToAnyPublisher()
  }

  func send(_ value: Output) {
    subject.send(value)
  }
}

extension PassthroughBacked where Output == Void {
  func send() {
    subject.send()
  }
}
