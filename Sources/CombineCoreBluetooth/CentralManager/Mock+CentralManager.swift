import Foundation
import Combine
import CoreBluetooth

extension CentralManager {
  public static func unimplemented(
    state: @escaping () -> CBManagerState = Internal._unimplemented("state"),
    authorization: @escaping () -> CBManagerAuthorization = Internal._unimplemented("authorization"),
    isScanning: @escaping () -> Bool = Internal._unimplemented("isScanning"),
    supportsFeatures: @escaping (Feature) -> Bool = Internal._unimplemented("supportsFeatures"),
    retrievePeripheralsWithIdentifiers: @escaping ([UUID]) -> [Peripheral] = Internal._unimplemented("retrievePeripheralsWithIdentifiers"),
    retrieveConnectedPeripheralsWithServices: @escaping ([CBUUID]) -> [Peripheral] = Internal._unimplemented("retrieveConnectedPeripheralsWithServices"),
    scanForPeripheralsWithServices: @escaping ([CBUUID]?, ScanOptions?) -> Void = Internal._unimplemented("scanForPeripheralsWithServices"),
    stopScanForPeripherals: @escaping () -> Void = Internal._unimplemented("stopScanForPeripherals"),
    connectToPeripheral: @escaping (Peripheral, PeripheralConnectionOptions?) -> Void = Internal._unimplemented("connectToPeripheral"),
    cancelPeripheralConnection: @escaping (Peripheral) -> Void = Internal._unimplemented("cancelPeripheralConnection"),
    registerForConnectionEvents: @escaping ([CBConnectionEventMatchingOption : Any]?) -> Void = Internal._unimplemented("registerForConnectionEvents"),

    didUpdateState: AnyPublisher<CBManagerState, Never> = Internal._unimplemented("didUpdateState"),
    willRestoreState: AnyPublisher<[String: Any], Never> = Internal._unimplemented("willRestoreState"),
    didConnectPeripheral: AnyPublisher<Peripheral, Never> = Internal._unimplemented("didConnectPeripheral"),
    didFailToConnectPeripheral: AnyPublisher<(Peripheral, Error?), Never> = Internal._unimplemented("didFailToConnectToPeripheral"),
    didDisconnectPeripheral: AnyPublisher<(Peripheral, Error?), Never> = Internal._unimplemented("didDisconnectPeripheral"),

    connectionEventDidOccur: AnyPublisher<(CBConnectionEvent, Peripheral), Never> = Internal._unimplemented("connectionEventDidOccur"),
    didDiscoverPeripheral: AnyPublisher<PeripheralDiscovery, Never> = Internal._unimplemented("didDiscoverPeripheral"),

    didUpdateACNSAuthorizationForPeripheral: AnyPublisher<Peripheral, Never> = Internal._unimplemented("didUpdateACNSAuthorizationForPeripheral")
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
