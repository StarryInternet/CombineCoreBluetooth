import Foundation
@preconcurrency import CoreBluetooth

/// Protocol that represents either a `Central` or a `Peripheral` when either could be present.
public protocol Peer: Sendable {
  var identifier: UUID { get }
}

extension Peripheral: Peer {}
extension Central: Peer {}

/// Wrapper for `CBPeer`s that (by some chance) are neither `Central`s nor `Peripheral`s.
public struct AnyPeer: Peer {
  public let identifier: UUID
  let rawValue: CBPeer?
  
  public init(identifier: UUID) {
    self.identifier = identifier
    self.rawValue = nil
  }
  
  init(_ cbpeer: CBPeer) {
    self.identifier = cbpeer.identifier
    self.rawValue = cbpeer
  }
}
