import CoreGraphics

extension Operation {
  struct Anchor: Sendable {
    let direction: WindowManagement.Direction
    let displays: [WindowManagement.Display]
    let padding: CGFloat
    let mode: WindowManagement.AnchorMode
    let minimumSize: CGSize?

    init(direction: WindowManagement.Direction, displays: [WindowManagement.Display], padding: CGFloat,
         mode: WindowManagement.AnchorMode = .nearest, minimumSize: CGSize? = nil) throws {
      guard padding.isFinite, padding >= 0 else { throw WindowManagement.AnchorError.invalidPadding }
      if let minimumSize {
        guard minimumSize.width.isFinite, minimumSize.height.isFinite,
              minimumSize.width >= 0, minimumSize.height >= 0 else { throw WindowManagement.AnchorError.invalidMinimumSize }
      }
      self.direction = direction
      self.displays = displays
      self.padding = padding
      self.mode = mode
      self.minimumSize = minimumSize
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
      let minimumWidth = max(1, (minimumSize?.width ?? 0).rounded(.up))
      let minimumHeight = max(1, (minimumSize?.height ?? 0).rounded(.up))
      guard availableWidth >= minimumWidth, availableHeight >= minimumHeight else { return nil }

      let offset = direction.offset
      let bands = [CGFloat(1) / 3, 0.5, CGFloat(2) / 3].map { scale in
        let width = offset.x == 0 ? availableWidth : max(minimumWidth, (availableWidth * scale).rounded())
        let height = offset.y == 0 ? availableHeight : max(minimumHeight, (availableHeight * scale).rounded())
        return CGRect(x: offset.x > 0 ? right - width : left, y: offset.y > 0 ? bottom - height : top,
                      width: width, height: height)
      }.filter(WindowManagement.isUsable)

      if case .cycle = mode,
         let current = bands.firstIndex(where: { FrameSettling(origin: $0.origin, size: $0.size).matches(original) }) {
        for step in 1 ..< bands.count {
          let next = bands[(current + step) % bands.count]
          if next != bands[current] { return next }
        }
      }

      func length(_ frame: CGRect) -> CGFloat { offset.x == 0 ? frame.height : frame.width }
      return bands.min { abs(length($0) - length(original)) < abs(length($1) - length(original)) }
    }
  }
}
