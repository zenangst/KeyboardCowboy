import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Search = WindowFocus.DirectionalSearch
private let source = CGRect(x: -600, y: 100, width: 500, height: 500)
private let adjacent = CGRect(x: 0, y: 150, width: 600, height: 600)
private let anchor = Search.Window(id: 1, frame: CGRect(x: -450, y: 180, width: 200, height: 200))
private let outer = Search.Window(id: 2, frame: CGRect(x: 250, y: 390, width: 170, height: 140))
private let inner = Search.Window(id: 3, frame: CGRect(x: 210, y: 390, width: 140, height: 140))

@Test(arguments: [false, true])
func displayHandoffUsesTheAnchorsNeighborAndPrefersTheReceivingEdge(leftward: Bool) throws {
  func mirror(_ frame: CGRect) -> CGRect {
    leftward ? CGRect(x: -frame.maxX, y: frame.minY, width: frame.width, height: frame.height) : frame
  }
  let farther = CGRect(x: 700, y: 150, width: 600, height: 600)
  let above = CGRect(x: -50, y: -500, width: 500, height: 500)
  let farWindow = Search.Window(id: 4, frame: CGRect(x: 950, y: 390, width: 200, height: 140))
  let windows = [inner, farWindow, outer].map { Search.Window(id: $0.id, frame: mirror($0.frame)) }
  var resolved: [CGWindowID] = []
  let match = try Search.select(
    from: .init(id: anchor.id, frame: mirror(anchor.frame)), windows: windows, direction: leftward ? .left : .right,
    visibleFrames: [farther, above, adjacent, source].map(mirror), mainDisplayFrame: mirror(farther),
    resolveAXIdentity: {
      resolved.append($0.id)
      return $0.id
    },
  ) { _ in nil }
  #expect(resolved == [inner.id])
  #expect(match?.windowID == inner.id)
  #expect(match?.direction == (leftward ? .left : .right))
  #expect(match?.branch == .displayEdge)
}

@Test func displayCenterSkipsMismatchedIdentityAndDoesNotAcceptGeometryAlone() throws {
  var resolved: [CGWindowID] = []
  let match = try Search.select(
    from: anchor, windows: [inner, outer], direction: .right, visibleFrames: [source, adjacent],
    resolveAXIdentity: {
      resolved.append($0.id)
      return $0.id == inner.id ? outer.id : $0.id
    },
  ) { _ in nil }
  #expect(resolved == [inner.id, outer.id])
  #expect(match?.windowID == outer.id)
  #expect(match?.branch == .displayEdge)
  let unverified = try Search.select(
    from: anchor, windows: [inner, outer], direction: .right, visibleFrames: [source, adjacent],
    resolveAXIdentity: { _ in nil },
  ) { _ in nil }
  #expect(unverified == nil)
}

@Test func spatialHitWinsBeforeDisplayCenterResolution() throws {
  let direct = Search.Window(id: 4, frame: CGRect(x: -160, y: 160, width: 140, height: 160))
  let match = try Search.select(
    from: anchor, windows: [inner, outer, direct], direction: .right, visibleFrames: [source, adjacent],
    resolveAXIdentity: { _ in
      Issue.record("Fallback resolver ran before the primary scan matched")
      return nil
    },
  ) { direct.frame.contains($0) ? direct.id : nil }
  #expect(match?.windowID == direct.id)
  #expect(match?.branch == .directHit)
}

@Test func verticalCenterFallbackPreservesSingleDisplaySelectionAndDoesNotReturnToTheSource() throws {
  let above = CGRect(x: source.minX, y: -500, width: source.width, height: 500)
  let overlapping = Search.Window(id: 2, frame: CGRect(x: -490, y: 280, width: 250, height: 190))
  let nested = Search.Window(id: 3, frame: CGRect(x: -440, y: 300, width: 120, height: 60))
  let aligned = Search.Window(id: 4, frame: CGRect(x: -490, y: 180, width: 300, height: 350))
  for displays in [[source], [source, above]] {
    var resolved: [CGWindowID] = []
    let match = try Search.select(
      from: anchor, windows: [nested, aligned, overlapping], direction: .up, visibleFrames: displays,
      resolveAXIdentity: {
        resolved.append($0.id)
        return $0.id
      },
    ) { _ in nil }
    #expect(resolved == (displays.count == 1 ? [overlapping.id] : []))
    #expect(match?.branch == (displays.count == 1 ? .displayCenter : nil))
  }
}

@Test(arguments: [false, true])
func verticalDisplayHandoffCrossesGapsAndFindsOffCenterWindows(upward: Bool) throws {
  let other = CGRect(x: -180, y: upward ? -660 : 760, width: 550, height: 500)
  let target = Search.Window(id: 5, frame: CGRect(x: 290, y: other.minY + 15, width: 60, height: 80))
  let decoy = Search.Window(id: 6, frame: anchor.frame)
  let match = try Search.select(
    from: anchor, windows: [decoy, target], direction: upward ? .up : .down, visibleFrames: [other, source],
    resolveAXIdentity: { $0.id },
  ) { _ in nil }
  #expect(match?.windowID == target.id)
  #expect(match?.branch == .displayEdge)
}

@Test func directionalHandoffSkipsEmptyAlignedDisplaysAndNeverReversesDirection() throws {
  let diagonal = CGRect(x: 150, y: -650, width: 500, height: 500)
  let target = Search.Window(id: 5, frame: CGRect(x: 300, y: -450, width: 150, height: 100))
  let opposite = CGRect(x: -1350, y: 100, width: 500, height: 500)
  let wrong = Search.Window(id: 6, frame: CGRect(x: -1200, y: 300, width: 150, height: 100))
  let windows = [target, wrong]
  var lookedUp: [CGWindowID] = []
  let match = try Search.select(
    from: anchor, windows: windows, direction: .right, visibleFrames: [source, adjacent, diagonal, opposite],
    resolveAXIdentity: { lookedUp.append($0.id); return $0.id },
  ) { _ in nil }
  #expect(lookedUp == [target.id])
  #expect(match?.windowID == target.id)
  let miss = try Search.select(
    from: anchor, windows: windows, direction: .right, visibleFrames: [source, opposite],
    resolveAXIdentity: { _ in Issue.record("No rightward display"); return nil },
  ) { _ in nil }
  #expect(miss == nil)
}

@Test(arguments: [30.0, 365.0, 680.0])
func rightwardIntentFindsAnOffAxisWindowFromEitherUnequalLeftWindow(targetY: Double) throws {
  let display = CGRect(x: 0, y: 0, width: 1200, height: 1000)
  let tall = Search.Window(id: 1, frame: CGRect(x: 40, y: 270, width: 350, height: 500))
  let small = Search.Window(id: 2, frame: CGRect(x: 100, y: 530, width: 240, height: 200))
  let target = Search.Window(id: 3, frame: CGRect(x: 740, y: targetY, width: 340, height: 200))
  for anchor in [tall, small] {
    var lookedUp: [CGWindowID] = []
    let match = try Search.select(
      from: anchor, windows: [tall, small, target], direction: .right, visibleFrames: [display],
      resolveAXIdentity: { lookedUp.append($0.id); return $0.id },
    ) { _ in nil }
    #expect(lookedUp == [target.id])
    #expect(match?.windowID == target.id)
    #expect(match?.branch == .offAxis)
  }
}

@Test func cancellationDuringDisplayCenterResolutionDoesNotReturnATarget() async {
  let task = Task {
    try Search.select(
      from: anchor, windows: [inner, outer], direction: .right, visibleFrames: [source, adjacent],
      resolveAXIdentity: { candidate in
        withUnsafeCurrentTask { $0?.cancel() }
        return candidate.id
      },
    ) { _ in nil }
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}
