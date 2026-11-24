import CoreGraphics

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

      // Keep the title bar reachable when the existing window is too tall.
      let x = visible.midX - window.width / 2
      let y = max(visible.minY, visible.midY - window.height / 2)
      let result = CGRect(origin: CGPoint(x: x, y: y), size: window.size)
      return WindowManagement.isUsable(result) ? result : nil
    }
  }
}
