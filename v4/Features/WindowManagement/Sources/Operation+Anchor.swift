import CoreGraphics

extension Operation {
  struct Anchor: Sendable {
    let direction: WindowManagement.Direction
    let displays: [WindowManagement.Display]
    let padding: CGFloat

    init(direction: WindowManagement.Direction, displays: [WindowManagement.Display], padding: CGFloat) throws {
      guard padding.isFinite, padding >= 0 else { throw WindowManagement.AnchorError.invalidPadding }
      self.direction = direction
      self.displays = displays
      self.padding = padding
    }

    func requestedFrame(for original: CGRect) -> CGRect? {
      guard let visible = WindowManagement.visibleBounds(for: original, on: displays),
            padding < visible.width / 2, padding < visible.height / 2 else { return nil }
      let padded = visible.insetBy(dx: padding, dy: padding)
      // Fit inside the padded bounds on a whole-point grid so AX and CG
      // agree on the origin when placement waits for the move to settle.
      let left = padded.minX.rounded(.up)
      let top = padded.minY.rounded(.up)
      let right = padded.maxX.rounded(.down)
      let bottom = padded.maxY.rounded(.down)
      let availableWidth = right - left
      let availableHeight = bottom - top
      guard availableWidth >= 1, availableHeight >= 1 else { return nil }

      let offset = direction.offset
      let scale = offset.x == 0
        ? nearestScale(to: original.height, within: availableHeight)
        : nearestScale(to: original.width, within: availableWidth)
      let width = offset.x == 0 ? availableWidth : max(1, (availableWidth * scale).rounded())
      let height = offset.y == 0 ? availableHeight : max(1, (availableHeight * scale).rounded())
      let result = CGRect(x: offset.x > 0 ? right - width : left, y: offset.y > 0 ? bottom - height : top,
                          width: width, height: height)
      return WindowManagement.isUsable(result) ? result : nil
    }

    private func nearestScale(to length: CGFloat, within available: CGFloat) -> CGFloat {
      [CGFloat(1) / 3, 0.5, CGFloat(2) / 3].min {
        abs((available * $0).rounded() - length) < abs((available * $1).rounded() - length)
      } ?? 0.5
    }
  }
}
