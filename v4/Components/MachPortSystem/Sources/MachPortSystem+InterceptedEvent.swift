import CoreGraphics
import Foundation

public extension MachPortSystem {
  /// A live event for synchronous use on the tap's owning run loop.
  /// Pass a snapshot, not the live event or its source, to asynchronous work.
  struct InterceptedEvent {
    public let id: UUID
    public let event: CGEvent
    public let eventSource: CGEventSource?
    public let type: CGEventType
    public let keyCode: Int64
    public let isRepeat: Bool

    /// Copies the captured keycode and current event flags and timestamp.
    /// Later event mutations do not change the snapshot.
    public func snapshot() -> EventSnapshot {
      EventSnapshot(self)
    }
  }
}
