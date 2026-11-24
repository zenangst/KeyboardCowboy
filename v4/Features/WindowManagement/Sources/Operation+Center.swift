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

      return WindowManagement.centeredFrame(window, in: visible)
    }
  }
}
