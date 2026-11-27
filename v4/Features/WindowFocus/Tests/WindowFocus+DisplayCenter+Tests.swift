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
func displayCenterUsesTheAnchorsNeighborAndRanksTheRequestedOuterEdge(leftward: Bool) throws {
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
  #expect(resolved == [outer.id])
  #expect(match?.windowID == outer.id)
  #expect(match?.direction == (leftward ? .left : .right))
  #expect(match?.branch == .displayCenter)
}

@Test func displayCenterSkipsMismatchedIdentityAndDoesNotAcceptGeometryAlone() throws {
  var resolved: [CGWindowID] = []
  let match = try Search.select(
    from: anchor, windows: [inner, outer], direction: .right, visibleFrames: [source, adjacent],
    resolveAXIdentity: {
      resolved.append($0.id)
      return $0.id == outer.id ? inner.id : $0.id
    },
  ) { _ in nil }
  #expect(resolved == [outer.id, inner.id])
  #expect(match?.windowID == inner.id)
  #expect(match?.branch == .displayCenter)
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

@Test func verticalCenterFallbackStaysOnSingleDisplay() throws {
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
