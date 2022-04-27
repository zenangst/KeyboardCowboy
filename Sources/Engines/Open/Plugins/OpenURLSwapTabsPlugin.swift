import Cocoa

final class OpenURLSwapTabsPlugin {
  enum OpenURLSwapToPluginError: Error {
    case failedToCreate
    case failedToCompile
    case failedToRun
  }

  func execute(_ command: OpenCommand) throws {
    var dictionary: NSDictionary?
    let script = try createAppleScript(command.path)

    _ = script.executeAndReturnError(&dictionary).booleanValue

    if dictionary != nil {
      throw OpenURLSwapToPluginError.failedToRun
    }
  }

  private func createAppleScript(_ urlString: String) throws -> NSAppleScript {
    let source = """
      set searchPattern to "\(urlString)"
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
        return false
      end tell
      """
    guard let appleScript = NSAppleScript(source: source) else {
      throw OpenURLSwapToPluginError.failedToCreate
    }
    return appleScript
  }
}
