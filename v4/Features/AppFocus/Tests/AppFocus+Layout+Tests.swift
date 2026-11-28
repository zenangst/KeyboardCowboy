@testable import AppFocusFeature
import CoreGraphics
import Testing
import WindowTilingFeature

private typealias Action = WindowTiling.Action

@Test func appFocusKeepsItsLegacyCountRules() {
  let cases: [(Action, [Action])] = [
    (.arrangeLeftRight, [.fill, .fill, .arrangeLeftRight, .arrangeLeftRight]),
    (.arrangeRightLeft, [.fill, .fill, .arrangeRightLeft, .arrangeRightLeft]),
    (.arrangeTopBottom, [.fill, .fill, .arrangeTopBottom, .arrangeTopBottom]),
    (.arrangeBottomTop, [.fill, .fill, .arrangeBottomTop, .arrangeBottomTop]),
    (.arrangeLeftQuarters, [.fill, .arrangeLeftRight, .arrangeLeftQuarters, .arrangeLeftQuarters]),
    (.arrangeRightQuarters, [.fill, .arrangeRightQuarters, .arrangeRightQuarters, .arrangeRightQuarters]),
    (.arrangeTopQuarters, [.fill, .arrangeTopBottom, .arrangeTopQuarters, .arrangeTopQuarters]),
    (.arrangeBottomQuarters, [.fill, .arrangeBottomTop, .arrangeBottomQuarters, .arrangeBottomQuarters]),
    (.arrangeQuarters, [.fill, .arrangeLeftRight, .arrangeLeftQuarters, .arrangeQuarters]),
    (.fill, [.fill, .fill, .fill, .fill]),
    (.center, [.center, .center, .center, .center]),
  ]
  let window = AppFocus.Window(id: 1, owner: 42, frame: CGRect(x: 0, y: 0, width: 400, height: 300))
  for (action, expected) in cases {
    let actual = (1 ... 4).map {
      AppFocus.layout(action, windows: Array(repeating: window, count: $0), snapshot: .init(frontmost: nil))
    }
    #expect(actual == expected.map(Optional.some))
  }
}

@Test func dynamicQuartersUsesTheFirstWindowAndItsDisplay() {
  let display = CGRect(x: -1000, y: 200, width: 1000, height: 800)
  let left = AppFocus.Window(id: 1, owner: 42, frame: CGRect(x: -1000, y: 200, width: 500, height: 800))
  let right = AppFocus.Window(id: 2, owner: 42, frame: CGRect(x: -500, y: 200, width: 500, height: 800))
  let snapshot = AppFocus.Snapshot(frontmost: nil, displays: [CGRect(x: 0, y: 0, width: 1000, height: 800), display])
  #expect(AppFocus.layout(.arrangeDynamicQuarters, windows: [left, right], snapshot: snapshot) == .arrangeLeftRight)
  #expect(AppFocus.layout(.arrangeDynamicQuarters, windows: [right, left], snapshot: snapshot) == .arrangeRightLeft)
  #expect(AppFocus.layout(.arrangeDynamicQuarters, windows: [right, left, left], snapshot: snapshot) == .arrangeRightQuarters)
  #expect(AppFocus.layout(.arrangeDynamicQuarters, windows: [left, right], snapshot: .init(frontmost: nil)) == .fill)
}
