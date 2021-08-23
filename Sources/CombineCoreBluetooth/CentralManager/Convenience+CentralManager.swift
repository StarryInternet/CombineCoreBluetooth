import Foundation

extension CentralManager {
  /// Monitors connection events to the given peripheral and represents them as a publisher that sends `true` on connect and `false` on disconnect.
  /// - Parameter peripheral: The peripheral to monitor for connection events.
  /// - Returns: A publisher that sends `true` on connect and `false` on disconnect for the given peripheral.
  public func monitorConnection(for peripheral: Peripheral) -> AnyPublisher<Bool, Never> {
    Publishers.Merge(
      didConnectPeripheral
        .filter { p in p == peripheral }
        .map { _ in true },
      didDisconnectPeripheral
        .filter { (p, error) in p == peripheral }
        .map { _ in false }
    )
    .eraseToAnyPublisher()
  }
}
