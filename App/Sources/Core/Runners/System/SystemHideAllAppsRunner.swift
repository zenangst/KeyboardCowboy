import Cocoa

final class SystemHideAllAppsRunner {
  static func run() {
    NSWorkspace.shared.runningApplications
      .filter { $0.activationPolicy == .regular || $0.isHidden == false }
      .forEach { runningApplication in
        runningApplication.hide()
    }
  }
}
