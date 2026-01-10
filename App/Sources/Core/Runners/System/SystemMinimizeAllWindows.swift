import Apps
import AXEssibility
import Carbon
import Cocoa
import Foundation
import MachPort

enum SystemMinimizeAllWindows {
  static func run(_ snapshot: UserSpace.Snapshot,
                  machPort _: MachPortEventController) throws {
    Task {
      var uniqueRunningApplications: [Application] = []
      for window in snapshot.windows.visibleWindowsInSpace {
        guard let runningApplication = NSWorkspace.shared
          .runningApplications
          .first(where: { $0.localizedName == window.ownerName }),
          let bundleIdentifier = runningApplication.bundleIdentifier else { continue }

        if !uniqueRunningApplications.contains(where: { $0.bundleIdentifier == bundleIdentifier }),
           let app = ApplicationStore.shared.application(for: bundleIdentifier) {
          uniqueRunningApplications.append(app)
          let appElement = AppAccessibilityElement(runningApplication.processIdentifier)
          var abort = false
          let minimize = try appElement.menuBar()
            .findChild(matching: { element, _ in
              element?.title == "Minimize All"
            }, abort: &abort)

          minimize?.performAction(.press)
        }
      }
    }
  }
}
