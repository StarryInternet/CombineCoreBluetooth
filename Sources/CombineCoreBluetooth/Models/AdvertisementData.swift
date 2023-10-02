import CoreBluetooth
import Foundation

/// Various kinds of data that are advertised by peripherals and obtained by the ``CentralManager`` during scanning.
public struct AdvertisementData: @unchecked Sendable {
  let dictionary: [String: Any]

  /// Initializes the advertisement data with the given dictionary, ideally obtained from `CoreBluetooth` itself.
  /// - Parameter dictionary: The advertisement data dictionary that backs all the properties of this type.
  public init(_ dictionary: [String: Any] = [:]) {
    self.dictionary = dictionary
  }

  /// Initializes the advertisement data with the given dictionary, ideally obtained from `CoreBluetooth` itself.
  /// - Parameter dictionary: The advertisement data dictionary that backs all the properties of this type.
  public init(_ dictionary: [Key: Any]) {
    self.dictionary = Dictionary(uniqueKeysWithValues: dictionary.map({ (key, value) in
      (key.rawValue, value)
    }))
  }

  /// The local name of a peripheral
  public var localName: String? {
    dictionary[Key.localName.rawValue] as? String
  }

  /// The transmit power of a peripheral.
  public var txPowerLevel: Double? {
    (dictionary[Key.txPowerLevel.rawValue] as? NSNumber)?.doubleValue
  }

  /// An array of advertised service UUIDs of a peripheral
  public var serviceUUIDs: [CBUUID]? {
    dictionary[Key.serviceUUIDs.rawValue] as? [CBUUID]
  }

  /// A dictionary that contains service-specific advertisement data.
  public var serviceData: [CBUUID: Data]? {
    dictionary[Key.serviceData.rawValue] as? [CBUUID: Data]
  }

  /// Manufacturer data of a peripheral
  public var manufacturerData: Data? {
    dictionary[Key.manufacturerData.rawValue] as? Data
  }

  /// An array of UUIDs found in the overflow area of the advertisement data.
  public var overflowServiceUUIDs: [CBUUID]? {
    dictionary[Key.overflowServiceUUIDs.rawValue] as? [CBUUID]
  }

  /// A Boolean value that indicates whether the advertising event type is connectable.
  public var isConnectable: Bool? {
    (dictionary[Key.isConnectable.rawValue] as? NSNumber)?.boolValue
  }

  // An array of solicited service UUIDs.
  public var solicitedServiceUUIDs: [CBUUID]? {
    dictionary[Key.solicitedServiceUUIDs.rawValue] as? [CBUUID]
  }

  /// Keys that may reference data in the ``AdvertisementData`` obtained by searching for peripherals.
  public struct Key: Equatable, Hashable, Sendable {
    public let rawValue: String

    private init(_ rawValue: String) {
      self.rawValue = rawValue
    }

    /// Key referencing the local name of a peripheral. Wrapper around `CBAdvertisementDataLocalNameKey` in `CoreBluetooth`
    public static let localName: Key             = .init(CBAdvertisementDataLocalNameKey)
    /// Key referencing the transmit power of a peripheral. Wrapper around `CBAdvertisementDataTxPowerLevelKey` in `CoreBluetooth`
    public static let txPowerLevel: Key          = .init(CBAdvertisementDataTxPowerLevelKey)
    /// Key referencing an array of advertised service UUIDs. Wrapper around `CBAdvertisementDataServiceUUIDsKey` in `CoreBluetooth`
    public static let serviceUUIDs: Key          = .init(CBAdvertisementDataServiceUUIDsKey)
    /// Key referencing a dictionary that contains service-specific advertisement data. Wrapper around `CBAdvertisementDataServiceDataKey` in `CoreBluetooth`
    public static let serviceData: Key           = .init(CBAdvertisementDataServiceDataKey)
    /// Key referencing the manufacturer data of a peripheral. Wrapper around `CBAdvertisementDataManufacturerDataKey` in `CoreBluetooth`
    public static let manufacturerData: Key      = .init(CBAdvertisementDataManufacturerDataKey)
    /// Key referencing an array of UUIDs found in the overflow area of the advertisement data. Wrapper around `CBAdvertisementDataOverflowServiceUUIDsKey` in `CoreBluetooth`
    public static let overflowServiceUUIDs: Key  = .init(CBAdvertisementDataOverflowServiceUUIDsKey)
    /// Key referencing a boolean value that indicates whether the advertising event type is connectable. Wrapper around `CBAdvertisementDataIsConnectable` in `CoreBluetooth`
    public static let isConnectable: Key         = .init(CBAdvertisementDataIsConnectable)
    /// Key referencing an array of solicited service UUIDs. Wrapper around `CBAdvertisementDataSolicitedServiceUUIDsKey` in `CoreBluetooth`
    public static let solicitedServiceUUIDs: Key = .init(CBAdvertisementDataSolicitedServiceUUIDsKey)
  }
}
