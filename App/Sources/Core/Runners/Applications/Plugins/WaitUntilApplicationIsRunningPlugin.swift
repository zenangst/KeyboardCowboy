import Foundation

final class WaitUntilApplicationIsRunningPlugin {
  static let debug: Bool = false

  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func run(for bundleIdentifier: String) async throws {
    #warning("Fix this properly, perhaps with another routine?")
    // Music does not play well with waiting for it to launch.
    let skippableBundleIdentifiers: [String] = ["com.apple.Music"]

    if skippableBundleIdentifiers.contains(bundleIdentifier) {
      return
    }

    var waiting: Bool = true
    var retries: Int = 20
    ifDebug("Waiting for \(bundleIdentifier)")
    while waiting {
      guard let application = workspace.applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        retries = retries - 1
        continue
      }

      if application.isFinishedLaunching {
        try await Task.sleep(for: .milliseconds(50))
        waiting = false
        ifDebug("done \(bundleIdentifier)")
        break
      }

      ifDebug("sleeping \(bundleIdentifier)")

      try? await Task.sleep(for: .milliseconds(100))

      retries = retries - 1

      if retries == 0 {
        waiting = false
        ifDebug("timed out \(bundleIdentifier)")
      }
    }
  }

  private func ifDebug(_ message: @autoclosure () -> String) {
    if Self.debug {
      print(message())
    }
  }
}
