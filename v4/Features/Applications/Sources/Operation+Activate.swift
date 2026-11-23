import ApplicationSystem
import Cocoa
import RuntimeEnvironment

extension Operation {
  final class Activate: Sendable {
    enum Result: Equatable {
      case activated, missingFrontmost, missingTarget, rejected, cancelled
    }

    typealias RunningApplication = ApplicationSystem.RunningApplication

    let env: RuntimeEnvironment.Mode
    let workspace: Application.Workspace

    init(_ env: RuntimeEnvironment.Mode) {
      self.env = env
      self.workspace = Application.Workspace(env)
    }

    @discardableResult
    func callAsFunction(_ bundleIdentifier: ApplicationSystem.BundleIdentifier) -> Result {
      guard !Task.isCancelled else { return .cancelled }
      guard let frontmostApplication = workspace.frontmostApplication else { return .missingFrontmost }
      guard let runningApplication = RunningApplication.application(with: bundleIdentifier, env: env) else {
        return Task.isCancelled ? .cancelled : .missingTarget
      }

      var options: NSApplication.ActivationOptions = []
      if frontmostApplication.bundleIdentifier?.value.lowercased() == bundleIdentifier.value.lowercased() {
        options.insert(.activateAllWindows)
      }

      guard !Task.isCancelled else { return .cancelled }

      return runningApplication.activate(from: frontmostApplication, options: options) ? .activated : .rejected
    }
  }
}
