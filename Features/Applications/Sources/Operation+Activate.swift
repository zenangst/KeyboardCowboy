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

    @discardableResult
    func callAsFunction(_ bundleIdentifier: BundleIdentifier) -> Bool {
      guard let frontmostApplication = workspace.frontmostApplication,
            let runningApplication = RunningApplication.runningApplication(
              with: bundleIdentifier, env: env) else {
        return false
      }

      var options: NSApplication.ActivationOptions = []
      if runningApplication.bundleIdentifier == frontmostApplication.bundleIdentifier {
        options.insert(.activateAllWindows)
      }

      return runningApplication.activate(from: frontmostApplication, options: options)
    }
  }
}
