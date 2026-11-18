import CoreGraphics
import Foundation

public extension MachPortSystem {
  /// Immutable event metadata suitable for passing to asynchronous work.
  struct EventSnapshot: Sendable {
    public let id: UUID
    public let typeRawValue: UInt32
    public let keyCode: Int64
    public let flagsRawValue: UInt64
    public let timestamp: UInt64
    public let isRepeat: Bool

    init(_ intercepted: InterceptedEvent) {
      id = intercepted.id
      typeRawValue = intercepted.type.rawValue
      keyCode = intercepted.keyCode
      flagsRawValue = intercepted.event.flags.rawValue
      timestamp = intercepted.event.timestamp
      isRepeat = intercepted.isRepeat
    }
  }
}
