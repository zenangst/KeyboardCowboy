import CoreGraphics
import Testing
import WindowTidyFeature
import WindowTilingFeature

private let display = CGRect(x: -1000, y: 100, width: 1000, height: 800)
private let left = CGRect(x: -1000, y: 100, width: 500, height: 800)
private let right = CGRect(x: -500, y: 100, width: 500, height: 800)
private let topLeft = CGRect(x: -1000, y: 100, width: 500, height: 400)
private let topRight = CGRect(x: -500, y: 100, width: 500, height: 400)
private let free = CGRect(x: -900, y: 225, width: 320, height: 245)

private func window(_ id: CGWindowID, _ frame: CGRect = free, owner: pid_t = 42,
                    bundle: String? = nil, onScreen: Bool = true) -> WindowTidy.Window {
  .init(id: id, owner: owner, frame: frame, bundleIdentifier: bundle, isOnScreen: onScreen)
}

@Test func singleAppPlansFillPairsAndQuartersOnTheOriginalAnchor() {
  let anchor = window(1, topRight)
  let windows = [anchor, window(2), window(3)]
  let actions: [WindowTiling.Action] = [.fill, .arrangeRightLeft, .arrangeRightQuarters]
  for (offset, action) in actions.enumerated() {
    let plan = WindowTidy.plan(windows: Array(windows.prefix(offset + 1)), visibleFrame: display)
    #expect(plan.steps.map(\.window.id) == [1])
    #expect(plan.steps.map(\.action) == [action])
    #expect(plan.restoreFocus == anchor)
  }
}

@Test func manyWindowsOfOneAppPreserveOppositeTilesAndProcessBackToFront() {
  let anchor = window(1, topLeft)
  let alreadyRight = window(2, topRight)
  let plan = WindowTidy.plan(windows: [anchor, alreadyRight, window(3, topLeft), window(4)], visibleFrame: display)
  #expect(plan.steps.map(\.window.id) == [4, 3, 1])
  #expect(plan.steps.map(\.action) == [.bottomRight, .topRight, .left])
  #expect(plan.restoreFocus == anchor)
}

@Test func multipleAppsForceOppositeHalvesOrQuartersAndSkipSettledWindows() {
  let anchor = window(1, left)
  let second = window(2, right, owner: 43)
  let alreadySettled = WindowTidy.plan(windows: [anchor, second], visibleFrame: display)
  #expect(alreadySettled.steps.isEmpty && alreadySettled.restoreFocus == nil)

  let third = window(3, owner: 44)
  let plan = WindowTidy.plan(windows: [anchor, second, third], visibleFrame: display)
  #expect(plan.steps.map(\.window.id) == [3, 2])
  #expect(plan.steps.map(\.action) == [.bottomRight, .topRight])
  #expect(plan.restoreFocus == anchor)
}

@Test func firstRuleReservesHalfAndSpareQuarterChoiceIsStable() {
  let windows = [
    window(1, owner: 41, bundle: "other"), window(2, owner: 42, bundle: "other"),
    window(3, owner: 43, bundle: "rule"), window(4, owner: 44, bundle: "rule"),
  ]
  let rules: [WindowTidy.Rule] = [
    .init(bundleIdentifier: "rule", tiling: .left), .init(bundleIdentifier: "rule", tiling: .right),
  ]
  let plan = WindowTidy.plan(windows: windows, visibleFrame: display, rules: rules)
  #expect(plan.steps.map(\.window.id) == [4, 3, 2])
  #expect(plan.steps.map(\.action) == [.left, .topRight, .bottomRight])
  #expect(plan == WindowTidy.plan(windows: windows, visibleFrame: display, rules: rules))
}

@Test func invalidOffScreenAndAmbiguousWindowsNeverEnterThePlan() {
  let anchor = window(1)
  let outside = window(2, CGRect(x: 0, y: 100, width: 400, height: 300))
  let windows = [outside, window(3, onScreen: false), window(4), window(4, owner: 43), window(0), anchor]
  let plan = WindowTidy.plan(windows: windows, visibleFrame: display)
  #expect(plan.steps.map(\.window.id) == [1])
  #expect(plan.steps.map(\.action) == [.fill])
  #expect(WindowTidy.plan(windows: windows, visibleFrame: .infinite).steps.isEmpty)
}
