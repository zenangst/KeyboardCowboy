import Carbon
import Foundation
@testable import HostInput
import KeyboardFeature
import KeyCodeSystem
import Testing

@MainActor
@Test func hostShortcutsUseTheRefreshedSnapshotWithoutReloading() throws {
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let french = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.French")
  let center = NotificationCenter()
  var next: KeyCodeSystem.Layout? = us
  var loads = 0
  let layouts = HostInput.KeyboardLayoutSession(center: center) {
    loads += 1
    guard let next else { throw KeyCodeSystem.LookupError.layoutUnavailable }

    return next
  }
  let shortcuts = [Keyboard.Shortcut(key: "a")]
  var codes: [Int?] = []
  try HostInput.withShortcutLayout(shortcuts, layouts: layouts) { snapshot in
    next = french
    center.post(name: HostInput.KeyboardLayoutSession.sourceChanged, object: nil)
    codes.append(snapshot.keyCode(for: "a"))
  }
  try HostInput.withShortcutLayout(shortcuts, layouts: layouts) { snapshot in
    codes.append(snapshot.keyCode(for: "a"))
  }
  #expect(codes == [kVK_ANSI_A, kVK_ANSI_Q])
  #expect(loads == 2)

  next = nil
  layouts.refresh()
  try HostInput.withShortcutLayout([], layouts: layouts) { _ in
    Issue.record("Empty input should not execute")
  }
  #expect(throws: KeyCodeSystem.LookupError.layoutUnavailable) {
    try HostInput.withShortcutLayout(shortcuts, layouts: layouts) { _ in
      Issue.record("Unavailable layout should not execute")
    }
  }
  #expect(throws: Keyboard.ExecutionError.posterUnavailable) {
    try HostInput.executeShortcuts([], using: nil, layouts: layouts)
  }
}
