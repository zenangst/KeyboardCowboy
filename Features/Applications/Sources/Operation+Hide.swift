import CowboyCore

extension Operation {
  final class Hide {
    private let env: Core.Environment
    private let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
    }

    func callAsFunction(_ bundleIdentifier: BundleIdentifier, snapshot: UserSpace.Snapshot) async {
      if bundleIdentifier == BundleIdentifier.WildCard.previous,
         await !snapshot.apps.previous.runningApplication.isHidden {
        await snapshot.apps.previous.runningApplication.hide()
        return
      }

      guard let application = Core.RunningApplication.runningApplication(with: bundleIdentifier, env: env) else {
        return
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

      _ = application.hide()
    }
  }
}
