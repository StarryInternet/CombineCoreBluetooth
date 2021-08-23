import Combine
import CoreBluetooth
import Foundation

public struct CentralManager {
  #if os(macOS) && !targetEnvironment(macCatalyst)
  public typealias Feature = Never
  #else
  public typealias Feature = CBCentralManager.Feature
  #endif

  let delegate: Delegate?

  let _state: () -> CBManagerState
  let _authorization: () -> CBManagerAuthorization
  let _isScanning: () -> Bool

  @available(macOS, unavailable)
  let _supportsFeatures: (_ feature: Feature) -> Bool

  let _retrievePeripheralsWithIdentifiers: ([UUID], CentralManager) -> [Peripheral]
  let _retrieveConnectedPeripheralsWithServices: ([CBUUID], CentralManager) -> [Peripheral]
  let _scanForPeripheralsWithServices: (_  serviceUUIDs: [CBUUID]?, _ options: [String : Any]?) -> Void
  let _stopScanForPeripherals: () -> Void
  let _connectToPeripheral: (Peripheral, _ options: [String: Any]?) -> AnyPublisher<Peripheral, Error>
  let _cancelPeripheralConnection: (_ peripheral: Peripheral) -> Void
  let _registerForConnectionEvents: (_ options: [CBConnectionEventMatchingOption : Any]?) -> Void

  public let didUpdateState: AnyPublisher<CBManagerState, Never>
  public let willRestoreState: AnyPublisher<[String: Any], Never>
  public let didConnectPeripheral: AnyPublisher<Peripheral, Never>
  public let didFailToConnectPeripheral: AnyPublisher<(Peripheral, Error?), Never>
  public let didDisconnectPeripheral: AnyPublisher<(Peripheral, Error?), Never>

  @available(macOS, unavailable)
  public let connectionEventDidOccur: AnyPublisher<(CBConnectionEvent, Peripheral), Never>
  public let didDiscoverPeripheral: AnyPublisher<PeripheralDiscovery, Never>

  @available(macOS, unavailable)
  public let didUpdateACNSAuthorizationForPeripheral: AnyPublisher<Peripheral, Never>

  public var state: CBManagerState {
    _state()
  }

  public var authorization: CBManagerAuthorization {
    _authorization()
  }

  public var isScanning: Bool {
    _isScanning()
  }

  @available(macOS, unavailable)
  public func supports(_ features: Feature) -> Bool {
    #if os(macOS) && !targetEnvironment(macCatalyst)
    // do nothing
    #else
    _supportsFeatures(features)
    #endif
  }

  public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
    _retrievePeripheralsWithIdentifiers(identifiers, self)
  }

  public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
    _retrieveConnectedPeripheralsWithServices(serviceUUIDs, self)
  }

  public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil) {
    _scanForPeripheralsWithServices(serviceUUIDs, options)
  }

  public func stopScan() {
    _stopScanForPeripherals()
  }

  public func connect(_ peripheral: Peripheral, options: [String: Any]? = nil) -> AnyPublisher<Peripheral, Error> {
    _connectToPeripheral(peripheral, options)
  }

  public func cancelPeripheralConnection(_ peripheral: Peripheral) {
    _cancelPeripheralConnection(peripheral)
  }

  public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption: Any]? = nil) {
    _registerForConnectionEvents(options)
  }
}
