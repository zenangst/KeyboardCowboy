import CoreGraphics
import Foundation

enum Operation {
  struct Center: Sendable {
    let displays: [WindowManagement.Display]

    func callAsFunction<Window: Equatable>(
      focusedWindow: () throws -> Window?,
      frame: (Window) throws -> CGRect,
      move: (CGPoint, Window) throws -> Void,
    ) throws -> WindowManagement.CenterResult? {
      try moveFocusedWindow(focusedWindow: focusedWindow, frame: frame, requested: requestedFrame, move: move)
    }

    func requestedFrame(for window: CGRect) -> CGRect? {
      guard let visible = WindowManagement.visibleBounds(for: window, on: displays) else { return nil }

      return WindowManagement.centeredFrame(window, in: visible)
    }

    func togglePlacement(
      in pid: pid_t, launchDate: Date?, id: CGWindowID, current: CGRect, onScreen: CGRect,
      point: WindowManagement.CenterRestorePoint?,
    ) -> WindowManagement.PlacementRequest? {
      guard FrameSettling.matchesOrigin(onScreen, current.origin),
            abs(onScreen.width - current.width) <= 1, abs(onScreen.height - current.height) <= 1 else { return nil }

      if let point, point.pid == pid, point.launchDate == launchDate, point.id == id,
         FrameSettling.matchesOrigin(current, point.centered.origin),
         point.centered.size == current.size, point.original.size == current.size,
         WindowManagement.displayIndex(for: point.original, on: displays) != nil {
        return .restore(point.original)
      }
      return requestedFrame(for: current).map(WindowManagement.PlacementRequest.place)
    }
  }
}
