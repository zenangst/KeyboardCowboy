import CoreGraphics

extension WindowFocus.DirectionalSearch {
  static func destinationDisplays(from source: CGRect, among displays: [CGRect], direction: Direction) -> [CGRect] {
    displays.compactMap { display -> (frame: CGRect, score: (Int, CGFloat, CGFloat))? in
      let forward = direction.forwardGap(from: source, to: display)
      guard forward >= 0 else { return nil }
      let sideways = direction.perpendicularGap(source, display)
      let offset = direction.isHorizontal ? abs(source.midY - display.midY) : abs(source.midX - display.midX)
      return (display, (sideways == 0 ? 0 : 1, hypot(forward, sideways), offset))
    }.sorted { $0.score < $1.score }.map(\.frame)
  }
}

extension WindowFocus.DirectionalSearch.Direction {
  var isHorizontal: Bool { self == .left || self == .right }

  func forwardGap(from source: CGRect, to target: CGRect) -> CGFloat {
    switch self {
    case .left: source.minX - target.maxX
    case .right: target.minX - source.maxX
    case .up: source.minY - target.maxY
    case .down: target.minY - source.maxY
    }
  }

  func perpendicularGap(_ first: CGRect, _ second: CGRect) -> CGFloat {
    if isHorizontal { return max(0, first.minY - second.maxY, second.minY - first.maxY) }
    return max(0, first.minX - second.maxX, second.minX - first.maxX)
  }

  func handoffScore(from anchor: CGRect, to target: CGRect, in display: CGRect) -> (CGFloat, CGFloat, CGFloat) {
    let offset = isHorizontal ? abs(anchor.midY - target.midY) : abs(anchor.midX - target.midX)
    let depth = switch self {
    case .right: target.minX - display.minX
    case .left: display.maxX - target.maxX
    case .down: target.minY - display.minY
    case .up: display.maxY - target.maxY
    }
    return (perpendicularGap(anchor, target), offset, max(0, depth))
  }
}
