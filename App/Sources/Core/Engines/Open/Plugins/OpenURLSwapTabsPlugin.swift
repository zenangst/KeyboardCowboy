import AXEssibility
import Windows
import Cocoa

final class OpenURLSwapTabsPlugin {
  enum OpenURLSwapToPluginError: Error {
    case failedToCreate
    case failedToCompile
    case failedToRun
    case couldFindOpenUrl
  }

  private let engine: ScriptEngine

  init(engine: ScriptEngine) {
    self.engine = engine
  }

  func execute(_ command: OpenCommand) async throws {
    let bundleIdentifier = command.application?.bundleIdentifier ?? "com.apple.Safari"
    if let runningApplication = NSWorkspace.shared.runningApplications
      .first(where: { $0.bundleIdentifier == bundleIdentifier })
    {
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
        throw OpenURLSwapToPluginError.couldFindOpenUrl
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
