import Foundation
import Testing
@testable import WindowTilingFeature

@Test func nativeActionsPreserveAllV3RawValuesAndIdentifiers() throws {
  let rawValues = """
    left right top bottom topLeft topRight bottomLeft bottomRight center fill zoom \
    arrangeLeftRight arrangeRightLeft arrangeTopBottom arrangeBottomTop arrangeLeftQuarters \
    arrangeRightQuarters arrangeTopQuarters arrangeBottomQuarters arrangeDynamicQuarters arrangeQuarters previousSize
    """.split(separator: " ").map(String.init)
  let selectors = """
    _zoomLeft: _zoomRight: _zoomTop: _zoomBottom: _zoomTopLeft: _zoomTopRight: \
    _zoomBottomLeft: _zoomBottomRight: _zoomCenter: _zoomFill: performZoom: _zoomLeftAndRight: \
    _zoomRightAndLeft: _zoomTopAndBottom: _zoomBottomAndTop: _zoomLeftThreeUp: _zoomRightThreeUp: \
    _zoomTopThreeUp: _zoomBottomThreeUp: _arrangeDynamicQuarters: _zoomQuarters: _zoomUntile:
    """.split(separator: " ").map(String.init)
  let actions = WindowTiling.Action.allCases
  #expect(actions.map(\.rawValue) == rawValues)
  #expect(actions.map(\.menuIdentifier) == selectors)
  let decoded = try JSONDecoder().decode([WindowTiling.Action].self, from: JSONEncoder().encode(rawValues))
  #expect(decoded == actions)
}

private struct MenuFixture {
  var children = [
    "bar": ["otherItem", "windowItem", "helpItem"],
    "otherItem": ["otherMenu"], "otherMenu": ["otherCenter", "otherFill"],
    "windowItem": ["windowMenu"], "windowMenu": ["center", "fill", "zoom", "misplaced", "resizeItem"],
    "resizeItem": ["resizeMenu"], "resizeMenu": ["left", "disabledRight", "right", "arrange", "previous"],
  ]
  let identifiers = [
    "otherCenter": "_zoomCenter:", "otherFill": "_zoomFill:", "center": "_zoomCenter:",
    "fill": "_zoomFill:", "zoom": "performZoom:", "misplaced": "_zoomRight:",
    "left": "_zoomLeft:", "disabledRight": "_zoomRight:", "right": "_zoomRight:",
    "arrange": "_zoomQuarters:", "previous": "_zoomUntile:",
  ]
  var disabled: Set<String> = ["disabledRight"]
  var picks: [String] = []

  mutating func execute(_ action: WindowTiling.Action) throws -> Bool {
    var selected: String?
    let result = try WindowTiling.execute(action, root: "bar", children: { children[$0, default: []] },
                                          identifier: { identifiers[$0] }, enabled: { !disabled.contains($0) },
                                          pick: { selected = $0 })
    if let selected { picks.append(selected) }
    return result
  }
}

@Test func selectsDirectAndSubmenuItemsInTheRightmostMatchingWindowMenu() throws {
  var menu = MenuFixture()
  for action in [WindowTiling.Action.center, .fill, .zoom, .right, .arrangeQuarters, .previousSize] {
    let picked = try menu.execute(action)
    #expect(picked)
  }
  #expect(menu.picks == ["center", "fill", "zoom", "right", "arrange", "previous"])
}

@Test func missingOrDisabledMenuItemsAreNotPicked() throws {
  var menu = MenuFixture()
  menu.disabled.formUnion(["right", "fill"])
  for action in [WindowTiling.Action.right, .fill, .top] {
    let picked = try menu.execute(action)
    #expect(!picked)
  }
  menu.disabled.insert("left")
  let missingSubmenu = try menu.execute(.previousSize)
  #expect(!missingSubmenu)
  menu.disabled.formUnion(["center", "otherCenter"])
  let missingWindowMenu = try menu.execute(.zoom)
  #expect(!missingWindowMenu)
  #expect(menu.picks.isEmpty)
}

@Test func pickFailurePropagatesWithoutRetry() {
  enum Failure: Error { case rejected }
  let menu = MenuFixture()
  var attempts = 0
  #expect(throws: Failure.rejected) {
    try WindowTiling.execute(.right, root: "bar", children: { menu.children[$0, default: []] },
                             identifier: { menu.identifiers[$0] }, enabled: { !menu.disabled.contains($0) },
                             pick: { _ in attempts += 1; throw Failure.rejected })
  }
  #expect(attempts == 1)
}

@Test func failedRevalidationSkipsAnEnabledPick() throws {
  let menu = MenuFixture()
  let accepted = try WindowTiling.execute(
    .fill, root: "bar", children: { menu.children[$0, default: []] },
    identifier: { menu.identifiers[$0] }, enabled: { !menu.disabled.contains($0) },
    canPick: { false }, pick: { _ in Issue.record("Unexpected menu pick") },
  )
  #expect(!accepted)
}
