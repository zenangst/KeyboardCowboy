import CoreGraphics
import Foundation
import Testing
@testable import WindowManagementFeature

@Test func fillRestoreRequiresMatchingIdentityAndFrameOnAnAvailableDisplay() {
  let display = CGRect(x: -1200, y: 20, width: 1200, height: 900)
  let displays = [WindowManagement.Display(bounds: display, visibleBounds: display)]
  let original = CGRect(x: -800, y: 250, width: 420, height: 280)
  let filled = display.insetBy(dx: 28, dy: 28)
  let point = WindowManagement.FillRestorePoint(pid: 42, launchDate: Date(), id: 12, original: original, filled: filled)
  #expect(point.target(id: 12, current: filled, onScreen: filled, displays: displays) == original)
  #expect(point.target(id: 13, current: filled, onScreen: filled, displays: displays) == nil)
  #expect(point.target(id: 12, current: filled.insetBy(dx: 0, dy: 20), onScreen: filled, displays: displays) == nil)
  #expect(point.target(id: 12, current: filled, onScreen: filled.offsetBy(dx: 4, dy: 0), displays: displays) == nil)
  #expect(point.target(id: 12, current: filled, onScreen: filled.insetBy(dx: 0, dy: 20), displays: displays) == nil)
  #expect(point.target(id: 12, current: filled, onScreen: filled, displays: []) == nil)
}

@Test func fillToggleRestoresOnlyTheMatchingPointAndOtherwiseFills() throws {
  let visible = CGRect(x: -1200, y: 20, width: 1200, height: 900)
  let displays = [WindowManagement.Display(bounds: visible, visibleBounds: visible)]
  let fill = try Operation.Fill(displays: displays, padding: 28)
  let launch = Date(timeIntervalSince1970: 100)
  let original = CGRect(x: -800, y: 250, width: 420, height: 280)
  let filled = visible.insetBy(dx: 28, dy: 28)
  let changed = filled.insetBy(dx: 40, dy: 40)
  let point = WindowManagement.FillRestorePoint(pid: 42, launchDate: launch, id: 12, original: original, filled: filled)
  #expect(fill.placement(in: 42, launchDate: launch, id: 12, current: filled, onScreen: filled, point: point) == .restore(original))
  #expect(fill.placement(in: 43, launchDate: launch, id: 12, current: filled, onScreen: filled, point: point) == .place(filled))
  #expect(fill.placement(in: 42, launchDate: launch + 1, id: 12, current: filled, onScreen: filled, point: point) == .place(filled))
  #expect(fill.placement(in: 42, launchDate: launch, id: 13, current: filled, onScreen: filled, point: point) == .place(filled))
  #expect(fill.placement(in: 42, launchDate: launch, id: 12, current: changed, onScreen: changed, point: point) == .place(filled))
}
