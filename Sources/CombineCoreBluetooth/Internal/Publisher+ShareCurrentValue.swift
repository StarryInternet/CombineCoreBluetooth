import Combine

extension Publisher {
  /// A variation on [share()](https://developer.apple.com/documentation/combine/publisher/3204754-share)
  /// that allows for buffering and replaying the most recent value to subscribers that connect after the most recent value is sent.
  ///
  /// - Returns: A publisher that replays latest value event to future subscribers.
  func shareCurrentValue() -> AnyPublisher<Output, Failure> {
    map(Optional.some)
      .multicast(subject: CurrentValueSubject<Output?, Failure>(nil))
      .autoconnect()
      .compactMap { $0 }
      .eraseToAnyPublisher()
  }
}
