import AXEssibility
import Cocoa
import Combine
import Foundation
import Windows

enum SystemWindowFocus {
  static func run(_ visibleMostIndex: inout Int, kind: SystemCommand.Kind,
                  snapshot: WindowStoreSnapshot, applicationStore: ApplicationStore,
                  workspace: WorkspaceProviding) throws {
    let collection = kind == .moveFocusToNextWindowGlobal ||
                     kind == .moveFocusToPreviousWindowGlobal
                     ? snapshot.visibleWindowsInSpace
                     : snapshot.visibleWindowsInStage

    let collectionCount = collection.count

    guard collectionCount > 1 else { return }

    switch kind {
    case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:
      visibleMostIndex += 1
      if visibleMostIndex >= collectionCount {
        visibleMostIndex = 0
      }
    default:
      visibleMostIndex -= 1
      if visibleMostIndex < 0 {
        visibleMostIndex = collectionCount - 1
      }
    }

    let window = collection[visibleMostIndex]
    let windowId = UInt32(window.id)
    let processIdentifier = pid_t(window.ownerPid.rawValue)
    let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
    let app = AppAccessibilityElement(processIdentifier)

    if let runningApplication = runningApplication {
      let options: NSApplication.ActivationOptions = [.activateIgnoringOtherApps]
      runningApplication.activate(options: options)

      if let bundleIdentifier = runningApplication.bundleIdentifier,
         bundleIdentifier != workspace.frontApplication?.bundleIdentifier,
         let application = applicationStore.application(for: bundleIdentifier) {
        let url = URL(fileURLWithPath: application.path)
        Task.detached { [workspace] in
          let configuration = NSWorkspace.OpenConfiguration()
          configuration.activates = true
          _ = try? await workspace.openApplication(at: url, configuration: configuration)
        }
      }
    }

    let axWindow = try app.windows().first(where: { $0.id == windowId })
    axWindow?.performAction(.raise)
  }
}
