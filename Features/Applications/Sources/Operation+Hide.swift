import CowboyCore

extension Operation {
  final class Hide: Sendable {
    private let env: Core.Environment
    private let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: BundleIdentifier, snapshot: UserSpace.Snapshot) async -> Bool {
      guard !Task.isCancelled else { return false }
      if bundleIdentifier == BundleIdentifier.WildCard.previous {
        if let previous = await snapshot.apps.previous, !previous.runningApplication.isHidden {
          guard !Task.isCancelled else { return false }
          previous.runningApplication.hide()
        }
        return false
      }

      guard let application = Core.RunningApplication.application(with: bundleIdentifier, env: env) else {
        return false
      }

      if let frontmostApplication = workspace.frontmostApplication,
         bundleIdentifier != frontmostApplication.bundleIdentifier {
        guard !Task.isCancelled else { return false }
        frontmostApplication.activate(options: [])
      }

      guard !Task.isCancelled else { return false }
      return application.hide()
    }
  }
}
