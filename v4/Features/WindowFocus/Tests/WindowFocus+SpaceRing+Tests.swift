import CoreGraphics
import Testing
import WindowFocusFeature

private typealias Ring = WindowFocus.SpaceRing

private func window(
  _ id: CGWindowID, owner: pid_t = 10, y: CGFloat = 0, width: CGFloat = 200,
  alpha: Double = 1, onScreen: Bool = true, name: String = "",
) -> Ring.Window {
  .init(id: id, owner: owner, frame: CGRect(x: 0, y: y, width: width, height: 180),
        alpha: alpha, isOnScreen: onScreen, ownerName: name)
}

@Test func currentSpaceRingFiltersInventoryAndWrapsAcrossApplications() {
  var ring = Ring()
  #expect(ring.select(.next) == nil)
  let top = window(1, y: -80)
  let middle = window(2, owner: 20, y: 10, alpha: 0.5)
  let bottom = window(3, owner: 30, y: 100)
  ring.update([top])
  #expect(ring.select(.previous) == nil)
  ring.update([
    bottom, middle, top, window(4, width: 100), window(5, alpha: 0),
    window(6, onScreen: false), window(7, name: "borders"), window(8, name: "Window Server"),
    window(9), window(9, owner: 20), window(0),
  ])
  #expect(ring.select(.next) == middle)
  for expected in [middle, bottom, top] {
    #expect(ring.select(.next) == expected)
    ring.observeFocus(windowID: expected.id, owner: expected.owner)
  }
  #expect(ring.select(.next) == middle)
}

@Test func previousPrefersObservedHistoryAndFallsBackWhenItDisappears() {
  var ring = Ring()
  let a = window(1)
  let b = window(2, owner: 20, y: 10)
  let c = window(3, owner: 30, y: 20)
  let d = window(4, owner: 40, y: 30)
  ring.update([a, b, c, d])
  ring.observeFocus(windowID: a.id, owner: a.owner)
  ring.observeFocus(windowID: c.id, owner: c.owner) // External focus puts C in A's cursor slot.
  ring.observeFocus(windowID: c.id, owner: c.owner) // Repeated observation doesn't overwrite history.
  #expect(ring.select(.previous) == a)
  ring.update([b, c, d])
  #expect(ring.select(.previous) == d)
}

@Test func refreshRetainsConfirmedCursorAndInsertsNewEntriesInSnapshotYOrder() {
  var ring = Ring()
  let a = window(1)
  let b = window(2, y: 10)
  let c = window(3, y: 20)
  ring.update([a, b, c])
  ring.observeFocus(windowID: a.id, owner: a.owner)
  #expect(ring.select(.next) == b)
  ring.observeFocus(windowID: b.id, owner: b.owner)

  let freshC = window(3, y: -100)
  let d = window(4, y: 21)
  let e = window(5, y: 22)
  ring.update([e, freshC, b, d, a])
  for expected in [d, e, freshC, a] {
    #expect(ring.select(.next) == expected)
    ring.observeFocus(windowID: expected.id, owner: expected.owner)
  }
}

@Test func cancelledSelectionDoesNotAdvanceAndReusedIDsDoNotCarryHistoryAcrossOwners() {
  var ring = Ring()
  let a = window(1)
  let b = window(2, y: 10)
  let c = window(3, owner: 30, y: 20)
  ring.update([a, b, c])
  ring.observeFocus(windowID: a.id, owner: a.owner)
  #expect(ring.select(.next) == b)
  ring.cancelSelection()
  #expect(ring.select(.next) == b)
  ring.observeFocus(windowID: b.id, owner: b.owner)

  let replacement = window(1, owner: 40, y: 0)
  ring.update([replacement, b, c])
  #expect(ring.select(.previous) == c)
  ring.reset()
  ring.update([c, b, replacement])
  #expect(ring.select(.next, frontmostOwner: c.owner) == replacement)
}
