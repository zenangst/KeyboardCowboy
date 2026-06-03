import Cocoa
import CowboyCore

extension Operation {
  final class Activate {
    typealias RunningApplication = Core.RunningApplication

    let env: Core.Environment
    let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
    }

    func callAsFunction(_ bundleIdentifier: BundleIdentifier) {
      guard let runningApplication = RunningApplication.runningApplication(
        with: bundleIdentifier, env: env) else {
        return
      }

      var options: NSApplication.ActivationOptions = []
      if runningApplication.bundleIdentifier == workspace.frontmostApplication?.bundleIdentifier {
        options.insert(.activateAllWindows)
      }

      _ = runningApplication.activate(from: runningApplication, options: options)
    }
  }
}
