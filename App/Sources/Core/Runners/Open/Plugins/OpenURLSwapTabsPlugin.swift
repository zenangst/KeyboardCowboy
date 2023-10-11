import Apps
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

  private let commandRunner: ScriptCommandRunner

  init(_ commandRunner: ScriptCommandRunner) {
    self.commandRunner = commandRunner
  }

  /// This function executes the open command, which opens a URL in a specific application.
  /// If the target application is already running, it uses accessibility services to find and activate the window/tab with the matching URL. If accessibility services fail, it will run an AppleScript as the fallback to switch to the correct tab.
  /// If the target application is not running, it opens the URL directly.
  /// - Parameters:
  ///   - command: The open command to execute.
  /// - Throws: An error if the URL cannot be opened.
  func execute(_ path: String, application: Application?) async throws {
    // Get the bundle identifier of the target application, default to Safari if not provided
    let bundleIdentifier = application?.bundleIdentifier ?? "com.apple.Safari"

    // Check if the target application is already running
    if let runningApplication = NSWorkspace.shared.runningApplications
      .first(where: { $0.bundleIdentifier == bundleIdentifier }) {

      let axApp = AppAccessibilityElement(runningApplication.processIdentifier)
      let windows = try axApp.windows()

      // Flag to track if the URL was successfully opened using accessibility services
      var success: Bool = false

      for window in windows {
        // Find the URL attribute of the web area in the window that matches the command path
        if let url: URL = window.findAttribute(.url, of: "AXWebArea"),
           url.absoluteString.contains(path) {
          window.performAction(.raise)
          runningApplication.activate(options: .activateIgnoringOtherApps)
          success = true
          break
        }
      }

      if !success {
        let appName = application?.displayName ?? "Safari"

        // Create an AppleScript to search for the URL in tabs
        //
        // This AppleScript code opens a specific URL in a specific application by swapping tabs.
        // It takes the path of the URL and the name of the application as input.
        // It activates the application and checks the URL of every tab in every window.
        // If it finds a tab with a URL that contains the desired URL, it sets that window as the active window and switches to the corresponding tab.
        // If it successfully swaps the tab, it returns 0. Otherwise, it returns -1.
        let source = """
            property matchingURL : "\(path)"
            tell application "\(appName)"
            activate
            set theURLs to (get URL of every tab of every window)
            repeat with x from 1 to length of theURLs
            set tmp to item x of theURLs
            repeat with y from 1 to length of tmp
            if item y of tmp contains matchingURL then
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

        // Run the script command and check the result
        if try await commandRunner.run(scriptCommand) == "-1" {
          throw OpenURLSwapToPluginError.couldNotFindOpenUrl
        }
      }
    } else if let url = URL(string: path) {
      // If the target application is not running, open the URL directly
      let configuration = NSWorkspace.OpenConfiguration()
      if let application = application {
        try await NSWorkspace.shared.open([url], withApplicationAt: URL(filePath: application.path),
                                          configuration: configuration)
      } else {
        NSWorkspace.shared.open(url)
      }
    }
  }
}
