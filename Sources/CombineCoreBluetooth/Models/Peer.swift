import Foundation

/// Protocol that represents either a `Central` or a `Peripheral` when either could be present.
public protocol Peer {
  var identifier: UUID { get }
}

extension Peripheral: Peer {}
extension Central: Peer {}

/// Type erased `Peer` for `CBPeer`s that (by some chance) are neither `Central`s nor `Peripheral`s.
struct AnyPeer: Peer {
  let identifier: UUID

  init(_ cbpeer: CBPeer) {
    self.identifier = cbpeer.identifier
  }
}
