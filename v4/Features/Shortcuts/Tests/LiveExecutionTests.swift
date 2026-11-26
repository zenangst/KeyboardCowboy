import Commands
import Foundation
import ShortcutsFeature
import Testing

@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_SHORTCUTS_LIVE_SMOKE"] == "1"))
func liveShortcutRunsByDiscoveredID() async throws {
  let matches = try await Shortcuts.Catalog().refresh().filter { $0.name == "KC_test" }
  try #require(matches.count == 1, "Create exactly one harmless shortcut named KC_test.")
  let entry = matches[0]
  let command = Command.Shortcut(shortcutIdentifier: entry.id.uuidString)
  _ = try await Shortcuts.Executor().run(command, cancellation: .checkBeforeLaunch)
}
