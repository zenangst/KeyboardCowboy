import CoreGraphics

extension WindowFocus.DirectionalSearch {
  static func displayCenterFallback(
    from anchor: Window, candidates: [Window], direction: Direction, displays: [CGRect],
    resolveAXIdentity: (Window) -> CGWindowID?,
  ) throws -> Match? {
    try Task.checkCancellation()
    let ranked = displays.map { display in
      let overlap = display.intersection(anchor.frame)
      return (display: display, area: overlap.isNull || overlap.isEmpty ? 0 : overlap.width * overlap.height)
    }
    guard let source = ranked.max(by: { $0.area < $1.area }), source.area > 0,
          let destination = destinationDisplay(from: source.display, among: displays, direction: direction) else {
      return nil
    }

    // v3 takes 40% of the source visible size and centers it on the destination.
    let width = min(source.display.width / 2.5, destination.width)
    let height = min(source.display.height / 2.5, destination.height)
    let probe = CGRect(x: destination.midX - width / 2, y: destination.midY - height / 2, width: width, height: height)
    let paddedAnchor = anchor.frame.insetBy(dx: -2, dy: -2)
    let ordered = switch direction {
    case .left: candidates.sorted { $0.frame.minX < $1.frame.minX }
    case .right: candidates.sorted { $0.frame.maxX > $1.frame.maxX }
    case .up, .down: candidates
    }
    for candidate in ordered {
      try Task.checkCancellation()
      let overlap = probe.intersection(candidate.frame)
      guard !paddedAnchor.contains(candidate.frame), !overlap.isNull, !overlap.isEmpty else { continue }
      switch direction {
      case .left, .right: guard candidate.frame.minX != anchor.frame.minX else { continue }
      case .up, .down: guard candidate.frame.minY != anchor.frame.minY else { continue }
      }
      let resolvedID = resolveAXIdentity(candidate)
      try Task.checkCancellation()
      if resolvedID == candidate.id {
        return .init(windowID: candidate.id, direction: direction, branch: .displayCenter)
      }
    }
    return nil
  }

  private static func destinationDisplay(from source: CGRect, among displays: [CGRect], direction: Direction) -> CGRect? {
    if displays.count == 1 { return source }
    // v3 has no vertical cross-display center fallback.
    guard direction == .left || direction == .right else { return nil }
    var best: (display: CGRect, gap: CGFloat, offset: CGFloat)?
    for display in displays {
      let gap = direction == .left ? source.minX - display.maxX : display.minX - source.maxX
      guard gap >= 0, display.minY < source.maxY, display.maxY > source.minY else { continue }
      let offset = abs(source.midY - display.midY)
      if let best, gap > best.gap || (gap == best.gap && offset >= best.offset) { continue }
      best = (display, gap, offset)
    }
    return best?.display
  }
}
