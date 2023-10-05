import Foundation
import Combine
import CoreBluetooth

extension CentralManager {
  public static func unimplemented(
    state: @escaping @Sendable () -> CBManagerState = _Internal._unimplemented("state"),
    authorization: @escaping @Sendable () -> CBManagerAuthorization = _Internal._unimplemented("authorization"),
    isScanning: @escaping @Sendable () -> Bool = _Internal._unimplemented("isScanning"),
    supportsFeatures: @escaping @Sendable (Feature) -> Bool = _Internal._unimplemented("supportsFeatures"),
    retrievePeripheralsWithIdentifiers: @escaping @Sendable ([UUID]) -> [Peripheral] = _Internal._unimplemented("retrievePeripheralsWithIdentifiers"),
    retrieveConnectedPeripheralsWithServices: @escaping @Sendable ([CBUUID]) -> [Peripheral] = _Internal._unimplemented("retrieveConnectedPeripheralsWithServices"),
    scanForPeripheralsWithServices: @escaping @Sendable ([CBUUID]?, ScanOptions?) -> Void = _Internal._unimplemented("scanForPeripheralsWithServices"),
    stopScanForPeripherals: @escaping @Sendable () -> Void = _Internal._unimplemented("stopScanForPeripherals"),
    connectToPeripheral: @escaping @Sendable (Peripheral, PeripheralConnectionOptions?) -> Void = _Internal._unimplemented("connectToPeripheral"),
    cancelPeripheralConnection: @escaping @Sendable (Peripheral) -> Void = _Internal._unimplemented("cancelPeripheralConnection"),
    registerForConnectionEvents: @escaping @Sendable ([CBConnectionEventMatchingOption : Any]?) -> Void = _Internal._unimplemented("registerForConnectionEvents"),

    didUpdateState: AnyPublisher<CBManagerState, Never> = _Internal._unimplemented("didUpdateState"),
    willRestoreState: AnyPublisher<[String: Any], Never> = _Internal._unimplemented("willRestoreState"),
    didConnectPeripheral: AnyPublisher<Peripheral, Never> = _Internal._unimplemented("didConnectPeripheral"),
    didFailToConnectPeripheral: AnyPublisher<(Peripheral, Error?), Never> = _Internal._unimplemented("didFailToConnectToPeripheral"),
    didDisconnectPeripheral: AnyPublisher<(Peripheral, Error?), Never> = _Internal._unimplemented("didDisconnectPeripheral"),

    connectionEventDidOccur: AnyPublisher<(CBConnectionEvent, Peripheral), Never> = _Internal._unimplemented("connectionEventDidOccur"),
    didDiscoverPeripheral: AnyPublisher<PeripheralDiscovery, Never> = _Internal._unimplemented("didDiscoverPeripheral"),

    didUpdateACNSAuthorizationForPeripheral: AnyPublisher<Peripheral, Never> = _Internal._unimplemented("didUpdateACNSAuthorizationForPeripheral")
  ) -> Self {
    return Self(
      delegate: nil,
      _state: state,
      _authorization: authorization,
      _isScanning: isScanning,
      _supportsFeatures: supportsFeatures,
      _retrievePeripheralsWithIdentifiers: retrievePeripheralsWithIdentifiers,
      _retrieveConnectedPeripheralsWithServices: retrieveConnectedPeripheralsWithServices,
      _scanForPeripheralsWithServices: scanForPeripheralsWithServices,
      _stopScan: stopScanForPeripherals,
      _connectToPeripheral: connectToPeripheral,
      _cancelPeripheralConnection: cancelPeripheralConnection,
      _registerForConnectionEvents: registerForConnectionEvents,

      didUpdateState: didUpdateState,
      willRestoreState: willRestoreState,
      didConnectPeripheral: didConnectPeripheral,
      didFailToConnectPeripheral: didFailToConnectPeripheral,
      didDisconnectPeripheral: didDisconnectPeripheral,
      connectionEventDidOccur: connectionEventDidOccur,
      didDiscoverPeripheral: didDiscoverPeripheral,
      didUpdateACNSAuthorizationForPeripheral: didUpdateACNSAuthorizationForPeripheral
    )
  }
}
