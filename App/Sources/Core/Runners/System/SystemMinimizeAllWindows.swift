import Apps
import Foundation
import Carbon
import Cocoa
import MachPort

enum SystemMinimizeAllWindows {
  static func run(_ snapshot: UserSpace.Snapshot, 
                  machPort: MachPortEventController) throws {
    Task {
      let menuBar = MenuBarCommandRunner()
      var uniqueRunningApplications: [Application] = []
      for window in snapshot.windows.visibleWindowsInSpace {
        guard let runningApplication = NSWorkspace.shared.runningApplications
          .first(where: { $0.localizedName == window.ownerName }),
              let bundleIdentifier = runningApplication.bundleIdentifier else { continue }

        if !uniqueRunningApplications.contains(where: { $0.bundleIdentifier == bundleIdentifier }),
           let app = ApplicationStore.shared.application(for: bundleIdentifier) {
          uniqueRunningApplications.append(app)
          let configuration = NSWorkspace.OpenConfiguration()
          configuration.activates = true

          let url = URL(fileURLWithPath: app.path)
          try Task.checkCancellation()
          try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
          try await menuBar.execute(.init(tokens: [
            .menuItem(name: "Window"), .menuItem(name: "Minimize All")
          ]))
        }
      }
    }
  }
}
