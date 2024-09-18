import Cocoa

final class SystemHideAllAppsRunner {
  static func run(workflowCommands: [Command]) {
    let exceptBundleIdentifiers = workflowCommands.compactMap {
      if case .application(let command) = $0, command.action == .open { return command.application.bundleIdentifier }
      return nil
    }

    NSWorkspace.shared.runningApplications
      .filter { !exceptBundleIdentifiers.contains($0.bundleIdentifier ?? "") }
      .filter { $0.activationPolicy == .regular || $0.isHidden == false }
      .forEach { runningApplication in
        runningApplication.hide()
    }
  }
}
