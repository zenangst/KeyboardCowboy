import CoreGraphics

extension WindowFocus.DirectionalSearch {
  static func displayCenterFallback(
    from anchor: Window, candidates: [Window], direction: Direction, displays: [CGRect],
    resolveAXIdentity: (Window) throws -> CGWindowID?,
  ) throws -> Match? {
    try Task.checkCancellation()
    guard let source = display(containing: anchor.frame, among: displays) else { return nil }
    let onDisplay = candidates.map { (window: $0, display: display(containing: $0.frame, among: displays)) }

    // An off-axis window entirely ahead on this display is a better match than
    // crossing displays or selecting a window that merely intersects the center.
    let ahead = onDisplay.filter {
      $0.display == source && direction.forwardGap(from: anchor.frame, to: $0.window.frame) >= 0
    }.map(\.window).sorted {
      let a = direction.forwardGap(from: anchor.frame, to: $0.frame)
      let b = direction.forwardGap(from: anchor.frame, to: $1.frame)
      return hypot(a, direction.perpendicularGap(anchor.frame, $0.frame))
        < hypot(b, direction.perpendicularGap(anchor.frame, $1.frame))
    }
    var checked = Set<CGWindowID>()
    func verified(_ candidate: Window, branch: Match.Branch) throws -> Match? {
      guard checked.insert(candidate.id).inserted else { return nil }
      try Task.checkCancellation()
      let resolved = try resolveAXIdentity(candidate)
      try Task.checkCancellation()
      guard resolved == candidate.id else { return nil }
      return .init(windowID: candidate.id, direction: direction, branch: branch)
    }
    for candidate in ahead {
      if let match = try verified(candidate, branch: .offAxis) { return match }
    }

    if displays.count > 1 {
      for destination in destinationDisplays(from: source, among: displays, direction: direction) {
        let ranked = onDisplay.filter { $0.display == destination }.map(\.window).sorted {
          direction.handoffScore(from: anchor.frame, to: $0.frame, in: destination)
            < direction.handoffScore(from: anchor.frame, to: $1.frame, in: destination)
        }
        for candidate in ranked {
          if let match = try verified(candidate, branch: .displayEdge) { return match }
        }
      }
      return nil
    }

    let paddedAnchor = anchor.frame.insetBy(dx: -2, dy: -2)
    let ordered = switch direction {
    case .left: candidates.sorted { $0.frame.minX < $1.frame.minX }
    case .right: candidates.sorted { $0.frame.maxX > $1.frame.maxX }
    case .up, .down: candidates
    }
    let width = source.width / 2.5
    let height = source.height / 2.5
    let probe = CGRect(x: source.midX - width / 2, y: source.midY - height / 2, width: width, height: height)
    for candidate in ordered {
      let aligned = direction.isHorizontal ? candidate.frame.minX == anchor.frame.minX : candidate.frame.minY == anchor.frame.minY
      guard !aligned, !paddedAnchor.contains(candidate.frame), overlapArea(candidate.frame, probe) > 0 else { continue }
      if let match = try verified(candidate, branch: .displayCenter) { return match }
    }
    return nil
  }

  static func display(containing frame: CGRect, among displays: [CGRect]) -> CGRect? {
    let best = displays.map { ($0, overlapArea($0, frame)) }.max { $0.1 < $1.1 }
    return best.flatMap { $0.1 > 0 ? $0.0 : nil }
  }

  private static func overlapArea(_ first: CGRect, _ second: CGRect) -> CGFloat {
    let overlap = first.intersection(second)
    return overlap.isNull || overlap.isEmpty ? 0 : overlap.width * overlap.height
  }
}
