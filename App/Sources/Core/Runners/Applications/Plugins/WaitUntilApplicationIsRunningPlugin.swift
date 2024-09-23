import Foundation

final class WaitUntilApplicationIsRunningPlugin {
  static let debug: Bool = false
  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func run(for bundleIdentifier: String) async throws {
    var waiting: Bool = true
    var retries: Int = 10
    ifDebug("Waiting for \(bundleIdentifier)")
    while waiting {
      guard let application = workspace.applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        retries = retries - 1
        continue
      }

      if application.isFinishedLaunching {
        try await Task.sleep(for: .milliseconds(25))
        waiting = false
        ifDebug("done \(bundleIdentifier)")
        break
      }

      ifDebug("sleeping \(bundleIdentifier)")

      try await Task.sleep(for: .milliseconds(100))

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
