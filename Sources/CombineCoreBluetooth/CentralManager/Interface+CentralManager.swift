import Combine
import CoreBluetooth
import Foundation

public struct CentralManager {
  #if os(macOS) && !targetEnvironment(macCatalyst)
  public typealias Feature = Never
  #else
  public typealias Feature = CBCentralManager.Feature
  #endif

  let _state: () -> CBManagerState
  let _authorization: () -> CBManagerAuthorization
  let _isScanning: () -> Bool

  @available(macOS, unavailable)
  let _supportsFeatures: (_ feature: Feature) -> Bool

  let _retrievePeripheralsWithIdentifiers: ([UUID]) -> [Peripheral]
  let _retrieveConnectedPeripheralsWithServices: ([CBUUID]) -> [Peripheral]
  let _scanForPeripheralsWithServices: (_  serviceUUIDs: [CBUUID]?, _ options: ScanOptions?) -> AnyPublisher<PeripheralDiscovery, Never>
  let _connectToPeripheral: (Peripheral, _ options: PeripheralConnectionOptions?) -> AnyPublisher<Peripheral, Error>
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
    return _supportsFeatures(features)
    #endif
  }

  public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
    _retrievePeripheralsWithIdentifiers(identifiers)
  }

  public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
    _retrieveConnectedPeripheralsWithServices(serviceUUIDs)
  }

  /// Starts scanning for peripherals that are advertising any of the services listed in `serviceUUIDs`
  ///
  /// To stop scanning for peripherals, cancel the subscription made to the returned publisher.
  /// - Parameters:
  ///   - serviceUUIDs:  A list of `CBUUID` objects representing the service(s) to scan for.
  ///   - options: An optional dictionary specifying options for the scan.
  /// - Returns: A publisher that sends values anytime peripherals are discovered that match the given service UUIDs.
  public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: ScanOptions? = nil) -> AnyPublisher<PeripheralDiscovery, Never> {
    _scanForPeripheralsWithServices(serviceUUIDs, options)
  }

  public func connect(_ peripheral: Peripheral, options: PeripheralConnectionOptions? = nil) -> AnyPublisher<Peripheral, Error> {
    _connectToPeripheral(peripheral, options)
  }

  public func cancelPeripheralConnection(_ peripheral: Peripheral) {
    _cancelPeripheralConnection(peripheral)
  }

  public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption: Any]? = nil) {
    _registerForConnectionEvents(options)
  }

  /// Configuration options used when creating a `CentralManager`.
  public struct CreationOptions {
    /// If true, display a warning dialog to the user when the `CentralManager` is instantiated if Bluetooth is powered off
    public var showPowerAlert: Bool?
    /// A unique identifier for the Central Manager that's being instantiated. This identifier is used by the system to identify a specific  CBCentralManager  instance for restoration and, therefore, must remain the same for subsequent application executions in order for the manager to be restored.
    public var restoreIdentifierKey: String?

    public init(showPowerAlert: Bool? = nil, restoreIdentifierKey: String? = nil) {
      self.showPowerAlert = showPowerAlert
      self.restoreIdentifierKey = restoreIdentifierKey
    }
  }

  /// Options used when scanning for peripherals.
  public struct ScanOptions {
    /// Whether or not the scan should filter duplicate peripheral discoveries
    public var allowDuplicates: Bool?
    /// Causes the scan to also look for peripherals soliciting any of the services contained in the list.
    public var solicitedServiceUUIDs: [CBUUID]?

    public init(allowDuplicates: Bool? = nil, solicitedServiceUUIDs: [CBUUID]? = nil) {
      self.allowDuplicates = allowDuplicates
      self.solicitedServiceUUIDs = solicitedServiceUUIDs
    }
  }

  /// Options used when connecting to a given `Peripheral`
  public struct PeripheralConnectionOptions {
    /// If true, indicates that the system should display a connection alert for a given peripheral, if the application is suspended when a successful connection is made.
    public var notifyOnConnection: Bool?
    /// If true, indicates that the system should display a disconnection alert for a given peripheral, if the application is suspended at the time of the disconnection.
    public var notifyOnDisconnection: Bool?
    /// if true, indicates that the system should display an alert for all notifications received from a given peripheral, if the application is suspended at the time.
    public var notifyOnNotification: Bool?
    /// The number of seconds for the system to wait before starting a connection.
    public var startDelay: TimeInterval?

    public init(notifyOnConnection: Bool? = nil, notifyOnDisconnection: Bool? = nil, notifyOnNotification: Bool? = nil, startDelay: TimeInterval? = nil) {
      self.notifyOnConnection = notifyOnConnection
      self.notifyOnDisconnection = notifyOnDisconnection
      self.notifyOnNotification = notifyOnNotification
      self.startDelay = startDelay
    }
  }
}
