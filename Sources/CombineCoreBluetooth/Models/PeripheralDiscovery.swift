import Foundation

public struct PeripheralDiscovery: Identifiable, Sendable {
  public let peripheral: Peripheral
  public let advertisementData: AdvertisementData
  public let rssi: Double?

  public init(peripheral: Peripheral, advertisementData: AdvertisementData, rssi: Double? = nil) {
    self.peripheral = peripheral
    self.advertisementData = advertisementData
    self.rssi = rssi
  }

  public var id: UUID {
    peripheral.id
  }
}
