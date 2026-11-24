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

    func requestedFrame(for original: CGRect) -> CGRect? {
      guard let visible = WindowManagement.visibleBounds(for: original, on: displays),
            padding < visible.width / 2, padding < visible.height / 2 else { return nil }
      let requested = visible.insetBy(dx: padding, dy: padding)
      return WindowManagement.isUsable(requested) ? requested : nil
    }
  }
}
