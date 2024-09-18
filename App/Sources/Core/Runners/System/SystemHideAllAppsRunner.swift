import Cocoa

final class SystemHideAllAppsRunner {
  static func run(workflowCommands: [Command]) async {
    let exceptBundleIdentifiers = workflowCommands.compactMap {
      if case .application(let command) = $0, command.action == .open { return command.application.bundleIdentifier }
      return nil
    }

    let apps = NSWorkspace.shared.runningApplications
      .filter { !exceptBundleIdentifiers.contains($0.bundleIdentifier ?? "") }
      .filter {
        guard let bundleURL = $0.bundleURL else { return false }
        let pathExtension = (bundleURL.lastPathComponent as NSString).pathExtension
        let path = bundleURL.path()

        guard pathExtension == "app" else { return false }
        guard !path.contains("Frameworks/") else { return false }

        return true
      }
      .filter { $0.activationPolicy == .regular && $0.isHidden == false }

    for app in apps {
      app.hide()
      try? await Task.sleep(for: .milliseconds(25))
    }
  }
}
