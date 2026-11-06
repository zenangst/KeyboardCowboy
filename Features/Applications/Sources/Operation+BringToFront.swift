import Cocoa
import CowboyCore

extension Operation {
  final class BringToFront: Sendable {
    let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    func callAsFunction() throws {
      try Task.checkCancellation()
      let source = """
      tell application "System Events"
        set frontmostProcess to first process where it is frontmost
        click (menu item "Bring All to Front" of menu "Window" of menu bar 1 of frontmostProcess)
      end tell
      """
      let appleScript = try Core.NSAppleScript(env, source: source)

      var errorInfo: NSDictionary?
      _ = try appleScript.executeAndReturnError(&errorInfo)
    }
  }
}
