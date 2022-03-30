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

  /// Applies the predicate to the first item in the Output's tuple; if it matches, take the first element from that and pass it along or throw any errors that are present.
  func filterFirstValueOrThrow<Value>(where predicate: @escaping (Value) -> Bool) -> AnyPublisher<Value, Error> where Output == (Value, Error?) {
    filterFirstValueOrThrow(where: { value, error in
      predicate(value)
    })
  }


  /// Applies the predicate to the first item in the Output's tuple; if it matches, take the first element from that and pass it along or throw any errors that are present.
  func filterFirstValueOrThrow<Value>(where predicate: @escaping (Value, Error?) -> Bool) -> AnyPublisher<Value, Error> where Output == (Value, Error?) {
    first(where: predicate)
      .tryMap { value, error in
        if let error = error { throw error }
        return value
      }
      .eraseToAnyPublisher()
  }
}
