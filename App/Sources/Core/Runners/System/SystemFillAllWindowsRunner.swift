import Apps
import AXEssibility
import Foundation
import Cocoa

final class SystemFillAllWindowsRunner {
  static func run(snapshot: UserSpace.Snapshot) async {
    Task {
      let windows = snapshot.windows.visibleWindowsInSpace.reversed()
      for window in windows {
        guard let runningApplication = NSWorkspace.shared.runningApplications
          .first(where: { $0.processIdentifier == window.ownerPid.rawValue }) else { continue }

        let appElement = AppAccessibilityElement(runningApplication.processIdentifier)
        guard let window = try? appElement.windows().first(where: { $0.id == window.id }) else { return }

        window.main = true

        if #available(macOS 14.0, *) {
          runningApplication.activate(from: NSWorkspace.shared.frontmostApplication!, options: .activateIgnoringOtherApps)
        } else {
          runningApplication.activate(options: .activateIgnoringOtherApps)
        }

        var abort = false
        let fill = try appElement.menuBar()
          .findChild(matching: { element, _ in
            element?.identifier == WindowTiling.fill.identifier
          }, abort: &abort)
        fill?.performAction(.pick)
      }
    }
  }
}
