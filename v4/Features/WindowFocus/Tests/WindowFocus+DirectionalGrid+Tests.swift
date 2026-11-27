import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Search = WindowFocus.DirectionalSearch

@Test(arguments: [false, true])
func directionalGridFollowsEveryHopEvenWhenRaisesChangeStacking(spokes: Bool) throws {
  let display = CGRect(x: -1240, y: 100, width: 1240, height: 950)
  let grid = (0 ..< 9).map { index -> Search.Window in
    let x = display.minX + 50 + CGFloat(index % 3) * 395
    let y = display.minY + 45 + CGFloat(index / 3) * 305
    return .init(id: CGWindowID(index + 1), frame: CGRect(x: x, y: y, width: 330, height: 240))
  }
  // IDs in reading order: 1 2 3 / 4 5 6 / 7 8 9.
  let route: [(Search.Direction, CGWindowID)] = spokes
    ? [(.left, 4), (.right, 5), (.up, 2), (.down, 5), (.right, 6), (.left, 5), (.down, 8), (.up, 5)]
    : [(.right, 2), (.right, 3), (.down, 6), (.down, 9), (.left, 8), (.left, 7), (.up, 4), (.right, 5)]
  var stacking = Array(grid.reversed())
  var anchor = grid[spokes ? 4 : 0]
  for (direction, expected) in route {
    let match = try Search.select(
      from: anchor, windows: stacking, direction: direction, visibleFrames: [display],
      resolveAXIdentity: { $0.id },
    ) { point in
      stacking.first { $0.frame.contains(point) }?.id
    }
    #expect(match?.windowID == expected, "From \(anchor.id), \(direction) should reach \(expected)")
    let selected = try #require(match?.windowID)
    let index = try #require(stacking.firstIndex { $0.id == selected })
    anchor = stacking.remove(at: index)
    stacking.insert(anchor, at: 0)
  }
  #expect(anchor.id == 5)
}
