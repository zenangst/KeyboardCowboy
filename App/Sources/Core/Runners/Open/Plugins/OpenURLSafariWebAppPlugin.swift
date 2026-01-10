import Apps
import AXEssibility
import Cocoa
import Foundation

final class OpenURLSafariWebAppPlugin: Sendable {
  private let commandRunner: ScriptCommandRunner

  init(_ commandRunner: ScriptCommandRunner) {
    self.commandRunner = commandRunner
  }

  func execute(_ path: String, application: Application, checkCancellation _: Bool) async throws {
    guard let runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: application.bundleIdentifier).first,
          let url = URL(string: path) else { return }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    try await NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: application.path), configuration: configuration)

    let axApp = AppAccessibilityElement(runningApplication.processIdentifier)

    let windows = try axApp.windows()
    if windows.count <= 1 {
      return
    }

    var timeout = 10
    while timeout > 0 {
      timeout -= 1
      try await Task.sleep(for: .milliseconds(100))

      let windows = try axApp.windows()
      for window in windows {
        if let url: URL = window.findAttribute(.url, of: "AXWebArea"),
           url.absoluteString.contains(path) {
          window.main = true
          window.performAction(.raise)
          timeout = 0
        }
      }
    }
  }
}
