import AccessibilitySystem
import CoreGraphics

public extension WindowManagement {
  /// Fills the active application's focused window within the display's usable
  /// area, inset by `padding`. Does not enter native fullscreen or save a
  /// restore frame. Returns nil if no target can be verified. A move that
  /// already happened is not rolled back.
  @discardableResult
  static func fillFocusedWindow(
    in processIdentifier: pid_t, displays: [Display], padding: CGFloat = 0,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> FrameResult? {
    try await fillIdentifiedFocusedWindow(in: processIdentifier, displays: displays, padding: padding, using: accessibility)?.frame
  }

  internal static func fillIdentifiedFocusedWindow(
    in processIdentifier: pid_t, displays: [Display], padding: CGFloat, using accessibility: AccessibilitySystem.Client,
  ) async throws -> (id: CGWindowID, frame: FrameResult)? {
    let fill = try Operation.Fill(displays: displays, padding: padding)
    guard !displays.isEmpty else { return nil }
    do {
      return try await placeIdentifiedFocusedWindow(in: processIdentifier, using: accessibility) { _, original, _ in
        fill.requestedFrame(for: original)
      }
    } catch FramePlacementError.settlingTimedOut {
      throw FillError.settlingTimedOut
    }
  }

  enum FillError: Error, Equatable {
    case invalidPadding
    case settlingTimedOut
  }
}
