import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Search = WindowFocus.DirectionalSearch

@Test(arguments: Search.Direction.allCases)
func displayEdgeHandoffKeepsTheAlignedRowOrColumn(direction: WindowFocus.DirectionalSearch.Direction) throws {
  func rotate(_ frame: CGRect) -> CGRect {
    switch direction {
    case .right: frame
    case .left: CGRect(x: -frame.maxX, y: frame.minY, width: frame.width, height: frame.height)
    case .down: CGRect(x: frame.minY, y: frame.minX, width: frame.height, height: frame.width)
    case .up: CGRect(x: frame.minY, y: -frame.maxX, width: frame.height, height: frame.width)
    }
  }
  func window(_ id: CGWindowID, x: CGFloat, y: CGFloat) -> Search.Window {
    .init(id: id, frame: rotate(CGRect(x: x, y: y, width: 260, height: 210)))
  }
  let source = rotate(CGRect(x: 0, y: 0, width: 900, height: 750))
  let destination = rotate(CGRect(x: 900, y: 0, width: 900, height: 750))
  let anchor = window(1, x: 630, y: 525)
  let edge = window(2, x: 910, y: 525)
  let deep = window(3, x: 1500, y: 525)
  let middle = window(4, x: 910, y: 270)
  let windows = [anchor, middle, deep, edge]
  let result = try Search.select(
    from: anchor, windows: windows, direction: direction, visibleFrames: [source, destination],
    resolveAXIdentity: { $0.id },
  ) { point in
    #expect(source.contains(point), "A handoff must not probe outside its source display")
    return windows.first { $0.frame.contains(point) }?.id
  }
  #expect(result?.windowID == edge.id)
  #expect(result?.branch == .displayEdge)
}

@Test func handoffDoesNotHitTestTheEmptySpaceAboveAShorterDisplay() throws {
  let source = CGRect(x: 0, y: 0, width: 2560, height: 1440)
  let sidecar = CGRect(x: 2560, y: 285, width: 1539, height: 1155)
  let anchor = Search.Window(id: 1, frame: CGRect(x: 2230, y: 10, width: 320, height: 230))
  let top = Search.Window(id: 2, frame: CGRect(x: 2570, y: 295, width: 320, height: 230))
  let middle = Search.Window(id: 3, frame: CGRect(x: 2570, y: 750, width: 320, height: 230))
  let match = try Search.select(
    from: anchor, windows: [anchor, middle, top], direction: .right, visibleFrames: [source, sidecar],
    resolveAXIdentity: { $0.id },
  ) { _ in
    Issue.record("The first probe is beyond the source edge, in empty space")
    return nil
  }
  #expect(match?.windowID == top.id)
  #expect(match?.branch == .displayEdge)
}

@Test func offsetDisplayPicksTheClosestActualRowRatherThanTheMatchingSlot() throws {
  let source = CGRect(x: -1000, y: -100, width: 1000, height: 900)
  let destination = CGRect(x: 140, y: 420, width: 820, height: 800)
  let anchor = Search.Window(id: 1, frame: CGRect(x: -340, y: 570, width: 330, height: 215))
  let top = Search.Window(id: 2, frame: CGRect(x: 150, y: 440, width: 340, height: 200))
  let middle = Search.Window(id: 3, frame: CGRect(x: 150, y: 680, width: 340, height: 215))
  let bottom = Search.Window(id: 4, frame: CGRect(x: 150, y: 1000, width: 340, height: 200))
  let result = try Search.select(
    from: anchor, windows: [anchor, bottom, top, middle], direction: .right, visibleFrames: [destination, source],
    resolveAXIdentity: { $0.id },
  ) { _ in nil }
  #expect(result?.windowID == middle.id)
  #expect(result?.branch == .displayEdge)
}
