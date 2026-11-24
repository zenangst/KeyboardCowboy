import CoreGraphics

extension Operation {
  struct Fill: Sendable {
    let displays: [WindowManagement.Display]
    let padding: CGFloat

    init(displays: [WindowManagement.Display], padding: CGFloat) throws {
      guard padding.isFinite, padding >= 0 else { throw WindowManagement.FillError.invalidPadding }
      self.displays = displays
      self.padding = padding
    }

    func callAsFunction<Window: Equatable>(
      focusedWindow: () throws -> Window?,
      frame: (Window) throws -> CGRect,
      setFrame: (CGRect, Window) throws -> CGRect,
    ) throws -> WindowManagement.FrameResult? {
      guard let window = try focusedWindow() else { return nil }
      let original = try frame(window)
      guard let visible = WindowManagement.visibleBounds(for: original, on: displays),
            padding < visible.width / 2, padding < visible.height / 2 else { return nil }

      let requested = visible.insetBy(dx: padding, dy: padding)
      guard WindowManagement.isUsable(requested) else { return nil }
      if original == requested {
        return .init(original: original, requested: requested, observed: original)
      }

      guard try focusedWindow() == window else { return nil }
      return try .init(original: original, requested: requested, observed: setFrame(requested, window))
    }
  }
}
