import AppKit

extension MenuBar {
  @MainActor
  struct Workspace {
    let frontmost: () -> Int32?
    let firstRunning: (String) -> Int32?
    let launch: @MainActor (URL) async throws -> Void
    let activate: (Int32) -> Bool

    static var live: Self {
      Self(
        frontmost: { NSWorkspace.shared.frontmostApplication?.processIdentifier },
        firstRunning: { identifier in
          NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .first(where: { !$0.isTerminated })?
            .processIdentifier
        },
        launch: { url in
          let configuration = NSWorkspace.OpenConfiguration()
          configuration.activates = false
          _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        },
        activate: { NSRunningApplication(processIdentifier: $0)?.activate() ?? false },
      )
    }
  }
}
