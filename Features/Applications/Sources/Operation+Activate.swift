import Cocoa
import CowboyCore

extension Operation {
  final class Activate: Sendable {
    enum Result: Equatable {
      case activated, missingFrontmost, missingTarget, rejected, cancelled
    }

    typealias RunningApplication = Core.RunningApplication

    let env: Core.Environment
    let workspace: Core.Workspace

    init(_ env: Core.Environment) {
      self.env = env
      self.workspace = Core.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: BundleIdentifier) -> Result {
      guard !Task.isCancelled else { return .cancelled }
      guard let frontmostApplication = workspace.frontmostApplication else { return .missingFrontmost }
      guard let runningApplication = RunningApplication.application(with: bundleIdentifier, env: env) else {
        return Task.isCancelled ? .cancelled : .missingTarget
      }

      var options: NSApplication.ActivationOptions = []
      if runningApplication.bundleIdentifier == frontmostApplication.bundleIdentifier {
        options.insert(.activateAllWindows)
      }

      guard !Task.isCancelled else { return .cancelled }
      return runningApplication.activate(from: frontmostApplication, options: options) ? .activated : .rejected
    }
  }
}
