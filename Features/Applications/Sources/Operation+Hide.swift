import CowboyCore

extension Operation {
  final class Hide {
    private let env: Core.Environment
    private let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: BundleIdentifier, snapshot: UserSpace.Snapshot) async -> Bool {
      if bundleIdentifier == BundleIdentifier.WildCard.previous,
         await !snapshot.apps.previous.runningApplication.isHidden {
        await snapshot.apps.previous.runningApplication.hide()
        return false
      }

      guard let application = Core.RunningApplication.runningApplication(with: bundleIdentifier, env: env) else {
        return false
      }

      if let frontmostApplication = workspace.frontmostApplication,
         bundleIdentifier != frontmostApplication.bundleIdentifier {
        await snapshot
          .apps
          .frontMost
          .runningApplication
          .activate(options: [],
          )
      }

      return application.hide()
    }
  }
}
