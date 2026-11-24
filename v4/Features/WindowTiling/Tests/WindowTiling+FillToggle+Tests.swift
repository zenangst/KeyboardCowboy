import AppKit
import CoreGraphics
import Testing
@testable import WindowTilingFeature

@Test func fillToggleRestoresOnlyWhenTheCurrentLayoutIsFill() {
  #expect(WindowTiling.fillToggleAction(current: .topRight, prior: nil) == .fill)
  #expect(WindowTiling.fillToggleAction(current: nil, prior: .left) == .fill)
  #expect(WindowTiling.fillToggleAction(current: .fill, prior: .topRight) == .topRight)
  #expect(WindowTiling.fillToggleAction(current: .fill, prior: nil) == nil)
}

@Test func fillHistoryIsScopedToTheWindowAppAndDisplayLayout() {
  let app = NSRunningApplication.current
  let bounds = CGRect(x: -1200, y: 24, width: 1200, height: 800)
  let point = WindowTiling.FillRestorePoint(application: app, id: 2, visibleBounds: bounds, margin: 8, tile: .left)
  #expect(point.matches(application: app, id: 2, visibleBounds: bounds, margin: 8))
  #expect(!point.matches(application: app, id: 3, visibleBounds: bounds, margin: 8))
  #expect(!point.matches(application: app, id: 2, visibleBounds: bounds.offsetBy(dx: 1, dy: 0), margin: 8))
  #expect(!point.matches(application: app, id: 2, visibleBounds: bounds, margin: 0))
}
