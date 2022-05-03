import Cocoa

final class OpenURLSwapTabsPlugin {
  enum OpenURLSwapToPluginError: Error {
    case failedToCreate
    case failedToCompile
    case failedToRun
  }

  func execute(_ command: OpenCommand) async throws {
    let engine = ScriptCommandEngine()
    let source = """
      set searchPattern to "\(command.path)"
      tell application "Safari"
        repeat with cWindow in windows
          repeat with cTab in tabs of cWindow
            set currentIndex to index of cTab
            set currentURL to URL of cTab
            if currentURL contains searchPattern then
              set index of cWindow to 1
              set current tab of cWindow to cTab
              set visible of cWindow to true
              tell application "System Events" to tell process "Safari"
                perform action "AXRaise" of window 1
                do shell script "open -j -a Safari"
              end tell
              delay 0.2
              set current tab of cWindow to cTab
              set visible of cWindow to true
              return true
              exit repeat
            end if
          end repeat
        end repeat
        error "Unable to find tab"
      end tell
      """
    let script = ScriptCommand.appleScript(
      id: "OpenURLSwapTabsPlugin",
      isEnabled: true, name: "Safari Swap Tabs",
      source: .inline(source))
    _ = try await engine.run(script)
  }
}
