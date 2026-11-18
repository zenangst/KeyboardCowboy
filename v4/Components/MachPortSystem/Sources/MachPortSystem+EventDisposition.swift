import CoreGraphics

public extension MachPortSystem {
  /// Return passThrough after mutating the original event, or replace it explicitly.
  enum EventDisposition {
    case passThrough
    case replace(CGEvent)
    case suppress
  }
}
