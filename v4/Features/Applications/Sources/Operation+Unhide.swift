import ApplicationSystem
import UserSpace
import RuntimeEnvironment

extension Operation {
  final class Unhide: Sendable {
    private let env: RuntimeEnvironment.Mode
    private let workspace: Application.Workspace

    init(_ env: RuntimeEnvironment.Mode) {
      self.env = env
      self.workspace = Application.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: ApplicationSystem.BundleIdentifier, snapshot _: UserSpace.Snapshot) async -> Bool {
      guard !Task.isCancelled else { return false }
      guard workspace.frontmostApplication?.bundleIdentifier != bundleIdentifier else { return false }
      guard let application = ApplicationSystem.RunningApplication.application(with: bundleIdentifier, env: env) else {
        return false
      }

      guard !Task.isCancelled else { return false }
      return application.unhide()
    }
  }
}
