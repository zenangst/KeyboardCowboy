import Foundation

public extension Application {
  /// Tracks one host-owned peek press. Timestamps must use the same monotonic clock.
  actor PeekSession {
    public enum Release: Equatable, Sendable {
      case unrelated, tap, hold, invalidTimestamp
    }

    private var active: (id: UUID, started: Duration)?

    public init() {}

    /// Use a fresh ID for each eligible workflow press and reuse it for its release.
    /// Repeats and presses while a session is active do not replace it.
    @discardableResult
    public func begin(id: UUID, at timestamp: Duration, isRepeat: Bool = false) -> Bool {
      guard !isRepeat, active == nil else { return false }
      active = (id, timestamp)
      return true
    }

    /// The host routes only `.hold` to release execution. A matching release always clears the session.
    public func release(id: UUID, at timestamp: Duration) -> Release {
      guard let active, active.id == id else { return .unrelated }
      self.active = nil
      guard timestamp >= active.started else { return .invalidTimestamp }
      return timestamp - active.started > .milliseconds(500) ? .hold : .tap
    }

    /// Clear a matching session after a failed or cancelled press.
    @discardableResult
    public func cancel(id: UUID) -> Bool {
      guard active?.id == id else { return false }
      active = nil
      return true
    }
  }
}
