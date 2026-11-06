import CowboyCore

extension Operation {
  final class Unhide: Sendable {
    private let env: Core.Environment
    private let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: BundleIdentifier, snapshot: UserSpace.Snapshot) async -> Bool {
      guard !Task.isCancelled else { return false }
      guard let application = Core.RunningApplication.application(with: bundleIdentifier, env: env) else {
        return false
      }

      if let frontmostApplication = workspace.frontmostApplication,
         bundleIdentifier != frontmostApplication.bundleIdentifier,
         let snapshotFrontmost = await snapshot.apps.frontMost {
        guard !Task.isCancelled else { return false }
        snapshotFrontmost.runningApplication.activate(options: [])
      }

      guard !Task.isCancelled else { return false }
      return application.unhide()
    }
  }
}
