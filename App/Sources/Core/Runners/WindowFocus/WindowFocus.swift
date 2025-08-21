import AXEssibility
import Cocoa
import Combine
import Foundation
import Windows

@MainActor
enum WindowFocus {
  private static var visibleMostIndex: Int = 0
  static var previousWindowId: CGWindowID?
  static var ring = [WindowModel]()

  static func frontMostApplicationChanged() {
    guard ring.count > 1 else { return }

    let frontmostApplication = NSWorkspace.shared.frontmostApplication!
    let currentApplication = AppAccessibilityElement(frontmostApplication.processIdentifier)

    guard let currentId = try? currentApplication.focusedWindow()?.id else {
      previousWindowId = nil
      return
    }
    guard let prevId = previousWindowId,
          currentId != prevId,
          let cIdx = ring.firstIndex(where: { $0.id == currentId }),
          let pIdx = ring.firstIndex(where: { $0.id == prevId })
    else {
      previousWindowId = currentId
      return
    }

    ring.move(ring[cIdx], after: ring[pIdx])

    if let prevElem = ring.first(where: { $0.id == prevId }) {
      ring.rotateTo(head: prevElem)
    }

    visibleMostIndex = min(1, ring.count - 1)
    previousWindowId = currentId
  }

  static func run(kind: WindowFocusCommand.Kind,
                  snapshot: WindowStoreSnapshot, applicationStore: ApplicationStore,
                  workspace: WorkspaceProviding) throws
  {
    let newCollection: [WindowModel]
    if kind == .moveFocusToNextWindowFront || kind == .moveFocusToPreviousWindowFront {
      newCollection = snapshot.visibleWindowsInSpace
        .filter { $0.ownerPid.rawValue == UserSpace.shared.frontmostApplication.ref.processIdentifier }

      if newCollection.isEmpty {
        CustomSystemRoutine(rawValue: UserSpace.shared.frontmostApplication.bundleIdentifier)?
          .routine(UserSpace.shared.frontmostApplication)
          .run(kind)
      }
    } else if kind == .moveFocusToNextWindow || kind == .moveFocusToPreviousWindow {
      newCollection = snapshot.visibleWindowsInStage
    } else {
      newCollection = kind == .moveFocusToNextWindowGlobal ||
        kind == .moveFocusToPreviousWindowGlobal
        ? snapshot.visibleWindowsInSpace
        : snapshot.visibleWindowsInStage
    }

    if !Self.ring.isEqual(to: newCollection) {
      for window in Self.ring {
        if !newCollection.contains(where: { $0.id == window.id }) {
          // If the window is no longer in the new collection, we need to remove it from
          // the snapshot to avoid stale references.
          if let index = Self.ring.firstIndex(where: { $0.id == window.id }) {
            Self.ring.remove(at: index)
          }
        }
      }

      for newWindow in newCollection {
        if !Self.ring.contains(where: { $0.id == newWindow.id }) {
          // If the new window is not in the snapshot, we add it.
          Self.ring.append(newWindow)
        }
      }
    }

    let collection: [WindowModel] = Self.ring
    let collectionCount = collection.count

    guard collectionCount > 1 else { return }

    let frontmostApplication = NSWorkspace.shared.frontmostApplication!
    let currentApplication = AppAccessibilityElement(frontmostApplication.processIdentifier)
    let currentId = try? currentApplication.focusedWindow()?.id

    switch kind {
    case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal, .moveFocusToNextWindowFront:
      visibleMostIndex = (visibleMostIndex + 1) % collectionCount
    default:
      visibleMostIndex = (visibleMostIndex - 1 + collectionCount) % collectionCount
    }

    var window = collection[visibleMostIndex]

    if let currentId, currentId == window.id {
      switch kind {
      case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal, .moveFocusToNextWindowFront:
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
         let application = applicationStore.application(for: bundleIdentifier)
      {
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
    previousWindowId = axWindow?.id
  }
}

private extension [WindowModel] {
  func isEqual(to other: [WindowModel]) -> Bool {
    let lhs = map(\.id).sorted(by: { $0 < $1 })
    let rhs = other.map(\.id).sorted(by: { $0 < $1 })
    return lhs == rhs
  }
}

private extension Array where Element: Equatable {
  /// Move `current` to immediately after `prev` in a circular sense.
  /// - Preserves order of all other elements.
  mutating func move(_ current: Element, after prev: Element) {
    guard count > 1,
          let p = firstIndex(of: prev),
          let c = firstIndex(of: current),
          p != c else { return }

    // If already adjacent with prev before current, nothing to do.
    if ((p + 1) % count) == c { return }

    let item = remove(at: c) // shrink array by one
    let newP = c < p ? p - 1 : p // prev shifts left if we removed before it
    insert(item, at: newP + 1) // place current right after prev
  }

  /// Rotate so that `head` becomes index 0 (optional, for presentation).
  mutating func rotateTo(head: Element) {
    guard let i = firstIndex(of: head), i != 0 else { return }

    self = Array(self[i...]) + self[..<i]
  }
}
