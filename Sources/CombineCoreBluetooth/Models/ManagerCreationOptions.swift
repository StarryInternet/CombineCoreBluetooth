import CoreBluetooth

/// Configuration options used when creating a `CentralManager` or `PeripheralManager`.
public struct ManagerCreationOptions: Sendable {
  /// If true, display a warning dialog to the user when the manager is instantiated if Bluetooth is powered off
  public var showPowerAlert: Bool?
  /// A unique identifier for the manager that's being instantiated. This identifier is used by the system to identify a specific  manager instance for restoration and, therefore, must remain the same for subsequent application executions in order for the manager to be restored.
  public var restoreIdentifierKey: String?
  
  public init(showPowerAlert: Bool? = nil, restoreIdentifierKey: String? = nil) {
    self.showPowerAlert = showPowerAlert
    self.restoreIdentifierKey = restoreIdentifierKey
  }
  
  var centralManagerDictionary: [String: Any] {
    var dict: [String: Any] = [:]
    dict[CBCentralManagerOptionShowPowerAlertKey] = showPowerAlert
    dict[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifierKey
    return dict
  }
  
  var peripheralManagerDictionary: [String: Any] {
    var dict: [String: Any] = [:]
    dict[CBPeripheralManagerOptionShowPowerAlertKey] = showPowerAlert
    dict[CBPeripheralManagerOptionRestoreIdentifierKey] = restoreIdentifierKey
    return dict
  }
}
