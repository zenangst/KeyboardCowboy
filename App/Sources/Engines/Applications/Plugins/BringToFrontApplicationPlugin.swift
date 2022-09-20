import Cocoa

/// Bring the current applications windows to front using Apple Scripting
/// This is only here because sending `.activateAllWindows` to `NSRunningApplication.activate()`
/// currently does not work as expected.
final class BringToFrontApplicationPlugin {
  private let engine: ScriptEngine

  init(engine: ScriptEngine) {
    self.engine = engine
  }

  func execute() async throws {
    let source = """
        tell application "System Events"
          set frontmostProcess to first process where it is frontmost
          click (menu item "Bring All to Front" of menu "Window" of menu bar 1 of frontmostProcess)
        end tell
        """

    _ = try await engine.run(
      ScriptCommand.appleScript(
        id: "BringToFrontApplicationPlugin",
        isEnabled: true,
        name: "BringToFrontApplicationPlugin",
        source: .inline(source)))
  }
}
