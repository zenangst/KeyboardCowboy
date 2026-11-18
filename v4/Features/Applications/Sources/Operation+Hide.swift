import ApplicationSystem
import UserSpace
import RuntimeEnvironment

extension Operation {
  final class Hide: Sendable {
    private let env: RuntimeEnvironment.Mode
    private let workspace: Application.Workspace

    init(_ env: RuntimeEnvironment.Mode) {
      self.env = env
      self.workspace = Application.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: ApplicationSystem.BundleIdentifier, snapshot: UserSpace.Snapshot) async -> Bool {
      guard !Task.isCancelled else { return false }
      if bundleIdentifier == ApplicationSystem.BundleIdentifier.WildCard.previous {
        if let previous = await snapshot.apps.previous, !previous.runningApplication.isHidden {
          guard !Task.isCancelled else { return false }
          previous.runningApplication.hide()
        }
        return false
      }

      guard let application = ApplicationSystem.RunningApplication.application(with: bundleIdentifier, env: env) else {
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
