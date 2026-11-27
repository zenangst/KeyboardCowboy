import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Search = WindowFocus.DirectionalSearch
private let anchor = Search.Window(id: 1, frame: CGRect(x: 200, y: 200, width: 100, height: 100))
private let display = CGRect(x: -100, y: -100, width: 800, height: 800)
private let covering = Search.Window(id: 2, frame: display)

@Test(arguments: Search.Direction.allCases)
func directionalProbesAdvanceBeforeTestingAndUseHitIdentity(direction: WindowFocus.DirectionalSearch.Direction) throws {
  let expected: [CGPoint] = switch direction {
  case .left: [.init(x: 125, y: 225), .init(x: 75, y: 225)]
  case .right: [.init(x: 425, y: 225), .init(x: 475, y: 225)]
  case .up: [.init(x: 325, y: 150), .init(x: 325, y: 100)]
  case .down: [.init(x: 225, y: 275), .init(x: 225, y: 325)]
  }
  let nearer = Search.Window(id: 3, frame: CGRect(x: 210, y: 210, width: 100, height: 100))
  var points: [CGPoint] = []
  let match = try Search.select(from: anchor, windows: [anchor, nearer, covering],
                                direction: direction, visibleFrames: [display]) { point in
    points.append(point)
    return points.count == 1 ? anchor.id : covering.id
  }
  #expect(points == expected)
  #expect(match?.windowID == covering.id)
  #expect(match?.branch == .directHit)
  #expect(match?.direction == direction)
}

@Test func deadzoneUsesGeometryConstraintsButStillRequiresExactAXIdentity() throws {
  let nested = Search.Window(id: 3, frame: CGRect(x: 210, y: 260, width: 40, height: 35))
  let withinTolerance = Search.Window(id: 4, frame: CGRect(x: 200, y: 202, width: 100, height: 180))
  let aligned = Search.Window(id: 5, frame: CGRect(x: 190, y: 250, width: 150, height: 50))
  let valid = Search.Window(id: 6, frame: CGRect(x: 190, y: 230, width: 150, height: 200))
  let main = CGRect(x: -275, y: 0, width: 1000, height: 700)
  let windows = [nested, withinTolerance, aligned, valid]
  for hit in [nil, 999, nested.id, withinTolerance.id, aligned.id, valid.id] as [CGWindowID?] {
    let match = try Search.select(from: anchor, windows: windows, direction: .down, visibleFrames: [display],
                                  mainDisplayFrame: main, deadzoneSpacing: 8, maxProbes: 1) { point in
      #expect(point == CGPoint(x: 225, y: 275))
      return hit
    }
    #expect(match?.windowID == (hit == valid.id ? valid.id : nil))
    #expect(match?.branch == (hit == valid.id ? .constrainedHit : nil))
  }
  let direct = try Search.select(from: anchor, windows: windows, direction: .down, visibleFrames: [display]) { _ in
    nested.id
  }
  #expect(direct?.windowID == nested.id)
}

@Test func topQuarterAlignmentUsesTheAnchorEdgesAndSpacing() throws {
  for (tiling, direction, point) in [
    (Search.Tiling.topLeft, Search.Direction.down, CGPoint(x: 233, y: 275)),
    (.topRight, .up, CGPoint(x: 267, y: 150)),
  ] {
    var points: [CGPoint] = []
    _ = try Search.select(from: anchor, windows: [covering], direction: direction,
                          visibleFrames: [display], tiling: tiling, spacing: 8, maxProbes: 1) {
      points.append($0)
      return nil
    }
    #expect(points == [point])
  }
}

@Test func tiledRightEdgeReroutesTheNextProbeDownward() throws {
  let bounds = CGRect(x: 0, y: 0, width: 460, height: 600)
  let target = Search.Window(id: 9, frame: CGRect(x: 400, y: 250, width: 200, height: 200))
  var points: [CGPoint] = []
  let match = try Search.select(from: anchor, windows: [target], direction: .right,
                                visibleFrames: [bounds], tiling: .left) { point in
    points.append(point)
    return target.frame.contains(point) ? target.id : nil
  }
  #expect(points == [.init(x: 425, y: 225), .init(x: 425, y: 275)])
  #expect(match?.windowID == target.id)
  #expect(match?.direction == .down)
}

@Test(arguments: [false, true])
func leftwardProbeCrossesAdjacentDisplaysButStopsAtAGap(hasGap: Bool) throws {
  let primary = CGRect(x: 0, y: 0, width: 500, height: 500)
  let secondary = CGRect(x: hasGap ? -600 : -500, y: -100, width: 500, height: 500)
  let anchor = Search.Window(id: 1, frame: CGRect(x: 25, y: 200, width: 100, height: 100))
  let target = Search.Window(id: 2, frame: CGRect(x: -250, y: 200, width: 151, height: 100))
  var points: [CGPoint] = []
  let match = try Search.select(from: anchor, windows: [target], direction: .left,
                                visibleFrames: [primary, secondary]) { point in
    points.append(point)
    return target.frame.contains(point) ? target.id : nil
  }
  #expect(points == (hasGap ? [.init(x: -50, y: 225)] : [.init(x: -50, y: 225), .init(x: -100, y: 225)]))
  #expect(match?.windowID == (hasGap ? nil : target.id))
}

@Test func noHitStopsAtProbeLimitAndInvalidGeometryDoesNotProbe() throws {
  var points: [CGPoint] = []
  let miss = try Search.select(from: anchor, windows: [covering], direction: .right,
                               visibleFrames: [display], maxProbes: 2) {
    points.append($0)
    return nil
  }
  #expect(miss == nil)
  #expect(points == [.init(x: 425, y: 225), .init(x: 475, y: 225)])

  let invalid = Search.Window(id: 4, frame: .infinite)
  for displays in [[CGRect](), [.null], [display]] {
    let windows = displays == [display] ? [invalid] : [covering]
    let match = try Search.select(from: anchor, windows: windows, direction: .right, visibleFrames: displays) { _ in
      Issue.record("Invalid search must not hit-test")
      return nil
    }
    #expect(match == nil)
  }
}

@Test func cancellationDuringAHitDoesNotReturnASelection() async {
  let task = Task {
    try Search.select(from: anchor, windows: [covering], direction: .right, visibleFrames: [display]) { _ in
      withUnsafeCurrentTask { $0?.cancel() }
      return covering.id
    }
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}
