import Foundation

public struct L2CAPChannel {
  public let peer: Peer
  public let inputStream: InputStream
  public let outputStream: OutputStream
  public let psm: CBL2CAPPSM
}

extension L2CAPChannel {
  init(channel: CBL2CAPChannel) {
    let peer: Peer
    if let peripheral = channel.peer as? CBPeripheral {
      peer = Peripheral(cbperipheral: peripheral)
    } else if let central = channel.peer as? CBCentral {
      peer = Central(cbcentral: central)
    } else {
      peer = AnyPeer(channel.peer)
    }

    self.init(
      peer: peer,
      inputStream: channel.inputStream,
      outputStream: channel.outputStream,
      psm: channel.psm
    )
  }
}
