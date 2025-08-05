import AXEssibility
import Cocoa
import Combine
import Foundation
import Windows

@MainActor
enum WindowFocus {
  static var windowSnapshot = [WindowModel]()

  static func run(_ visibleMostIndex: inout Int, kind: WindowFocusCommand.Kind,
                  snapshot: WindowStoreSnapshot, applicationStore: ApplicationStore,
                  workspace: WorkspaceProviding) throws {
    let newCollection = kind == .moveFocusToNextWindowGlobal ||
                        kind == .moveFocusToPreviousWindowGlobal
                        ? snapshot.visibleWindowsInSpace
                        : snapshot.visibleWindowsInStage

   if !Self.windowSnapshot.isEqual(to: newCollection) {

     for window in Self.windowSnapshot {
       if !newCollection.contains(where: { $0.id == window.id }) {
         // If the window is no longer in the new collection, we need to remove it from
         // the snapshot to avoid stale references.
         if let index = Self.windowSnapshot.firstIndex(where: { $0.id == window.id }) {
           Self.windowSnapshot.remove(at: index)
         }
       }
     }

     for newWindow in newCollection {
       if !Self.windowSnapshot.contains(where: { $0.id == newWindow.id }) {
         // If the new window is not in the snapshot, we add it.
         Self.windowSnapshot.append(newWindow)
       }
     }
   }

    let collection: [WindowModel] = Self.windowSnapshot
    let collectionCount = collection.count

    guard collectionCount > 1 else { return }

    let frontmostApplication = NSWorkspace.shared.frontmostApplication!
    let currentApplication = AppAccessibilityElement(frontmostApplication.processIdentifier)
    let currentId = try? currentApplication.focusedWindow()?.id

    switch kind {
    case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:
      visibleMostIndex = (visibleMostIndex + 1) % collectionCount
    default:
      visibleMostIndex = (visibleMostIndex - 1 + collectionCount) % collectionCount
    }

    var window = collection[visibleMostIndex]

    if let currentId, currentId == window.id {
      switch kind {
      case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:
        visibleMostIndex = (visibleMostIndex - 1 + collectionCount) % collectionCount
      default:
        visibleMostIndex = (visibleMostIndex + 1) % collectionCount
      }

      window = collection[visibleMostIndex]
    }

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

private extension [WindowModel] {
  func isEqual(to other: [WindowModel]) -> Bool {
    let lhs = self.map(\.id).sorted(by: { $0 < $1 })
    let rhs = other.map(\.id).sorted(by: { $0 < $1 })
    return lhs == rhs
  }
}
