import Foundation
import CoreBluetooth

public struct L2CAPChannel {
  // Need to keep a reference to this so the system doesn't close the channel
  let rawValue: CBL2CAPChannel?
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
      rawValue: channel,
      peer: peer,
      inputStream: channel.inputStream,
      outputStream: channel.outputStream,
      psm: channel.psm
    )
  }
  
  public init(peer: Peer, inputStream: InputStream, outputStream: OutputStream, psm: CBL2CAPPSM) {
    self.init(
      rawValue: nil,
      peer: peer,
      inputStream: inputStream,
      outputStream: outputStream,
      psm: psm
    )
  }
}
