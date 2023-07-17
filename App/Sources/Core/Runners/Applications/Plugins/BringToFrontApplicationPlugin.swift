import Cocoa

/// Bring the current applications windows to front using Apple Scripting
/// This is only here because sending `.activateAllWindows` to `NSRunningApplication.activate()`
/// currently does not work as expected.
final class BringToFrontApplicationPlugin {
  private let commandRunner: ScriptCommandRunner

  init(_ commandRunner: ScriptCommandRunner) {
    self.commandRunner = commandRunner
  }

  func execute() async throws {
    let source = """
        tell application "System Events"
          set frontmostProcess to first process where it is frontmost
          click (menu item "Bring All to Front" of menu "Window" of menu bar 1 of frontmostProcess)
        end tell
        """

    try Task.checkCancellation()
    _ = try await commandRunner.run(
      ScriptCommand(name: "BringToFrontApplicationPlugin", kind: .appleScript, source: .inline(source), notification: false)
    )
  }
}
