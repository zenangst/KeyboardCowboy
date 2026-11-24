import CoreGraphics

enum Operation {
  struct Center: Sendable {
    let displays: [WindowManagement.Display]

    func callAsFunction<Window: Equatable>(
      focusedWindow: () throws -> Window?,
      frame: (Window) throws -> CGRect,
      move: (CGPoint, Window) throws -> Void,
    ) throws -> WindowManagement.CenterResult? {
      guard let window = try focusedWindow() else { return nil }
      let original = try frame(window)
      guard let requested = requestedFrame(for: original) else { return nil }
      if original.origin == requested.origin {
        return .init(original: original, requested: requested, observed: original)
      }

      guard try focusedWindow() == window else { return nil }
      try move(requested.origin, window)
      return try .init(original: original, requested: requested, observed: frame(window))
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
