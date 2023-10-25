import CoreBluetooth

/// Configuration options used when creating a `CentralManager` or `PeripheralManager`.
public struct ManagerCreationOptions: Sendable {
  /// If true, display a warning dialog to the user when the manager is instantiated if Bluetooth is powered off
  public var showPowerAlert: Bool?
  /// A unique identifier for the manager that's being instantiated. This identifier is used by the system to identify a specific  manager instance for restoration and, therefore, must remain the same for subsequent application executions in order for the manager to be restored.
  public var restoreIdentifier: String?
  
  public init(showPowerAlert: Bool? = nil, restoreIdentifier: String? = nil) {
    self.showPowerAlert = showPowerAlert
    self.restoreIdentifier = restoreIdentifier
  }
  
  var centralManagerDictionary: [String: Any] {
    var dict: [String: Any] = [:]
    dict[CBCentralManagerOptionShowPowerAlertKey] = showPowerAlert
    dict[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
    return dict
  }
  
  var peripheralManagerDictionary: [String: Any] {
    var dict: [String: Any] = [:]
    dict[CBPeripheralManagerOptionShowPowerAlertKey] = showPowerAlert
    dict[CBPeripheralManagerOptionRestoreIdentifierKey] = restoreIdentifier
    return dict
  }
  
  @available(*, deprecated, renamed: "restoreIdentifier")
  public var restoreIdentifierKey: String? {
    get { restoreIdentifier }
    set { restoreIdentifier = newValue }
  }
  
  @available(*, deprecated, renamed: "init(showPowerAlert:restoreIdentifier:)")
  public init(showPowerAlert: Bool? = nil, restoreIdentifierKey: String?) {
    self.init(showPowerAlert: showPowerAlert, restoreIdentifier: restoreIdentifierKey)
  }
}
