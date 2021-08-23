import CoreBluetooth
import Foundation

public struct AdvertisementData {
  let dictionary: [String: Any]

  public init(_ dictionary: [String: Any] = [:]) {
    self.dictionary = dictionary
  }

  public init(_ dictionary: [Key: Any]) {
    self.dictionary = Dictionary(uniqueKeysWithValues: dictionary.map({ (key, value) in
      (key.rawValue, value)
    }))
  }

  public var localName: String? {
    dictionary[Key.localName.rawValue] as? String
  }

  public var txPowerLevel: Double? {
    (dictionary[Key.txPowerLevel.rawValue] as? NSNumber)?.doubleValue
  }

  public var serviceUUIDs: [CBUUID]? {
    dictionary[Key.serviceUUIDs.rawValue] as? [CBUUID]
  }

  public var serviceData: [CBUUID: Data]? {
    dictionary[Key.serviceData.rawValue] as? [CBUUID: Data]
  }

  public var manufacturerData: Data? {
    dictionary[Key.manufacturerData.rawValue] as? Data
  }

  public var overflowServiceUUIDs: [CBUUID]? {
    dictionary[Key.overflowServiceUUIDs.rawValue] as? [CBUUID]
  }

  public var isConnectable: Bool? {
    (dictionary[Key.isConnectable.rawValue] as? NSNumber)?.boolValue
  }

  public var solicitedServiceUUIDs: [CBUUID]? {
    dictionary[Key.solicitedServiceUUIDs.rawValue] as? [CBUUID]
  }

  public struct Key: Equatable, Hashable {
    public let rawValue: String

    private init(_ rawValue: String) {
      self.rawValue = rawValue
    }

    public static let localName: Key             = .init(CBAdvertisementDataLocalNameKey)
    public static let txPowerLevel: Key          = .init(CBAdvertisementDataTxPowerLevelKey)
    public static let serviceUUIDs: Key          = .init(CBAdvertisementDataServiceUUIDsKey)
    public static let serviceData: Key           = .init(CBAdvertisementDataServiceDataKey)
    public static let manufacturerData: Key      = .init(CBAdvertisementDataManufacturerDataKey)
    public static let overflowServiceUUIDs: Key  = .init(CBAdvertisementDataOverflowServiceUUIDsKey)
    public static let isConnectable: Key         = .init(CBAdvertisementDataIsConnectable)
    public static let solicitedServiceUUIDs: Key = .init(CBAdvertisementDataSolicitedServiceUUIDsKey)
  }
}
