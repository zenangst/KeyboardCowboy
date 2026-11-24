import AccessibilitySystem
import AppKit
import CoreGraphics
import Darwin

public extension WindowTiling {
  /// Picks Dynamic Quarters based on the active app's focused window.
  /// The caller supplies the eligible count and usable display geometry.
  /// With multiple windows, unclassified geometry is a no-op; Center and
  /// horizontal tiles prefer the right, while Fill prefers the left.
  /// Returns the native action accepted by AX, not a settled layout.
  @discardableResult
  static func arrangeDynamicQuarters(
    in pid: pid_t, eligibleWindowCount: Int, visibleBounds: CGRect, margin: CGFloat,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> Action? {
    guard pid > 0, pid != getpid(), eligibleWindowCount > 0, validLayout(visibleBounds, margin: margin),
          let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier == pid else { return nil }

    return try await accessibility.withApplication(processIdentifier: pid) { session in
      guard let window = try session.focusedWindow(), let id = try session.windowIDCandidate(for: window),
            let frame = onScreenFrame(id: id, pid: pid), frame.intersects(visibleBounds),
            let action = dynamicAction(count: eligibleWindowCount, layout: classify(frame, in: visibleBounds, margin: margin))
      else { return nil }

      let accepted = try execute(action, in: session) {
        guard NSWorkspace.shared.frontmostApplication?.isEqual(app) == true,
              try session.focusedWindow() == window else { return false }

        return onScreenFrame(id: id, pid: pid) == frame
      }
      return accepted ? action : nil
    }
  }

  internal static func dynamicAction(count: Int, layout: Action?) -> Action? {
    let side: ArrangementSide? = switch layout {
    case .left, .topLeft, .bottomLeft, .fill: .left
    case .right, .topRight, .bottomRight, .center, .top, .bottom: .right
    default: nil
    }
    return resolvedAction(.arrangeDynamicQuarters, eligibleWindowCount: count, dynamicSide: side)
  }
}
