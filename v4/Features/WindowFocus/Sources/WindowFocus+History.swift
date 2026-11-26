#if DEBUG || WINDOW_FOCUS_VALIDATION
import CoreGraphics

public extension WindowFocus {
  /// A host-provided focus transition for the active app. Discard it when
  /// the app instance changes; the executor does not observe or store history.
  struct History: Sendable {
    let processIdentifier: pid_t
    let current: CGWindowID
    let previous: CGWindowID

    public init(processIdentifier: pid_t, current: CGWindowID, previous: CGWindowID) {
      self.processIdentifier = processIdentifier
      self.current = current
      self.previous = previous
    }
  }
}
#endif
