import ApplicationSystem
import UserSpace
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
    func callAsFunction(_ bundleIdentifier: BundleIdentifier, snapshot _: UserSpace.Snapshot) async -> Bool {
      guard !Task.isCancelled else { return false }
      guard workspace.frontmostApplication?.bundleIdentifier != bundleIdentifier else { return false }
      guard let application = Core.RunningApplication.application(with: bundleIdentifier, env: env) else {
        return false
      }

      guard !Task.isCancelled else { return false }
      return application.unhide()
    }
  }
}
