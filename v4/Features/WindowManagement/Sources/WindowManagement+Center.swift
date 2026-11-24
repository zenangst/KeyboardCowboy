import AccessibilitySystem
import CoreGraphics
import Darwin

public enum WindowManagement {
  /// Bounds and usable area in AX global coordinates (top-left origin).
  public struct Display: Sendable {
    public let bounds: CGRect
    public let visibleBounds: CGRect

    public init(bounds: CGRect, visibleBounds: CGRect) {
      self.bounds = bounds
      self.visibleBounds = visibleBounds
    }
  }

  public typealias CenterResult = FrameResult

  public struct FrameResult: Equatable, Sendable {
    public let original: CGRect
    public let requested: CGRect
    public let observed: CGRect
  }

  /// Centers the specified application's focused window without resizing it.
  /// Returns nil if no display intersects the window or the target is unavailable.
  @discardableResult
  public static func centerFocusedWindow(
    in processIdentifier: pid_t, displays: [Display],
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CenterResult? {
    // AX can call an in-process AppKit setter inline on the off-main worker.
    guard processIdentifier > 0, processIdentifier != getpid(), !displays.isEmpty else { return nil }

    let center = Operation.Center(displays: displays)
    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      try center(
        focusedWindow: session.focusedWindow,
        frame: { try session.frame(of: $0) },
        move: { try session.write(.position, value: $0, to: $1) },
      )
    }
  }
}
