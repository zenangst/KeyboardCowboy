import AXEssibility
import Windows
import Cocoa

final class OpenURLSwapTabsPlugin {
  enum OpenURLSwapToPluginError: Error {
    case failedToCreate
    case failedToCompile
    case failedToRun
    case couldNotFindOpenUrl
  }

  private let engine: ScriptEngine

  init(engine: ScriptEngine) {
    self.engine = engine
  }

  func execute(_ command: OpenCommand) async throws {
    let bundleIdentifier = command.application?.bundleIdentifier ?? "com.apple.Safari"
    if let runningApplication = NSWorkspace.shared.runningApplications
      .first(where: { $0.bundleIdentifier == bundleIdentifier }) {
      let axApp = AppAccessibilityElement(runningApplication.processIdentifier)
      let windows = try axApp.windows()
      var success: Bool = false

      for window in windows {
        if let url: URL = window.findAttribute(.url, of: "AXWebArea"),
            url.absoluteString.contains(command.path) {
          window.performAction(.raise)
          success = true
          runningApplication.activate(options: .activateIgnoringOtherApps)
          break
        }
      }

      if !success {
        let appName = command.application?.displayName ?? "Safari"
        let source = """
property wantedURL : "\(command.path)"
tell application "\(appName)"
  activate
  set theURLs to (get URL of every tab of every window)
  repeat with x from 1 to length of theURLs
    set tmp to item x of theURLs
    repeat with y from 1 to length of tmp
      if item y of tmp contains wantedURL then
        set the index of window x to 1
        tell window 1
          if index of current tab is not y then set current tab to tab y
          return 0
        end tell
      end if
    end repeat
  end repeat
  return -1
end tell
"""
        let scriptCommand = ScriptCommand(name: UUID().uuidString, kind: .appleScript, source: .inline(source), notification: false)
        if try await engine.run(scriptCommand) == "-1" {
          throw OpenURLSwapToPluginError.couldNotFindOpenUrl
        }
      }
    } else if let url = URL(string: command.path) {
      let configuration = NSWorkspace.OpenConfiguration()
      if let application = command.application {
        try await NSWorkspace.shared.open([url], withApplicationAt: URL(filePath: application.path),
                                          configuration: configuration)
      } else {
        NSWorkspace.shared.open(url)
      }
    }
  }
}
