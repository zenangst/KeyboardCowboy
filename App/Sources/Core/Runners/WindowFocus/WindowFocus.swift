import AXEssibility
import Cocoa
import Combine
import Foundation
import RingBuffer
import Windows

@MainActor
enum WindowFocus {
  enum Ring: String { case app, global, stage }

  private static var visibleMostIndexByRing: [Ring: Int] = [:]
  static var previousWindowIds = [Ring: CGWindowID]()
  static var appRing = RingBuffer<WindowModel>()
  static var globalRing = RingBuffer<WindowModel>()
  static var stageRing = RingBuffer<WindowModel>()
  static var skipNextApplicationChange = false

  static func frontMostApplicationChanged() {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else { return }

    let newAppWindows = WindowStore.shared
      .getWindows(onScreen: true)
      .filter { $0.ownerPid.rawValue == frontmostApplication.processIdentifier }

    appRing.update(newAppWindows)

    let processIdentifier = frontmostApplication.processIdentifier
    let app = AppAccessibilityElement(processIdentifier)
    guard let id = try? app.focusedWindow()?.id,
          let window = newAppWindows.first(where: { $0.id == id })
    else {
      return
    }

    if skipNextApplicationChange {
      appRing.setCursor(to: window)
      globalRing.setCursor(to: window)
      stageRing.setCursor(to: window)
      skipNextApplicationChange = false
    } else {
      appRing.moveEntryToCursor(window)
      globalRing.moveEntryToCursor(window)
      stageRing.moveEntryToCursor(window)
    }
  }

  static func run(kind: WindowFocusCommand.Kind,
                  snapshot: WindowStoreSnapshot,
                  applicationStore: ApplicationStore,
                  workspace: WorkspaceProviding) throws
  {
    let newCollection: [WindowModel]
    let ring: RingBuffer<WindowModel>

    if kind == .moveFocusToNextWindowFront || kind == .moveFocusToPreviousWindowFront {
      newCollection = snapshot.visibleWindowsInSpace
        .filter { $0.ownerPid.rawValue == UserSpace.shared.frontmostApplication.ref.processIdentifier }

      if newCollection.isEmpty {
        CustomSystemRoutine(rawValue: UserSpace.shared.frontmostApplication.bundleIdentifier)?
          .routine(UserSpace.shared.frontmostApplication)
          .run(kind)
      }
      ring = appRing
    } else if kind == .moveFocusToNextWindow || kind == .moveFocusToPreviousWindow {
      newCollection = snapshot.visibleWindowsInStage
      ring = stageRing
    } else if kind == .moveFocusToNextWindowGlobal || kind == .moveFocusToPreviousWindowGlobal {
      newCollection = snapshot.visibleWindowsInSpace
      ring = globalRing
    } else {
      return
    }

    let direction: RingBufferDirection = switch kind {
    case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal, .moveFocusToNextWindowFront:
      .right
    default:
      .left
    }

    guard newCollection.count > 1 else { return }
    guard let window = ring.navigate(direction, entries: newCollection) else {
      return
    }

    let windowId = UInt32(window.id)
    let processIdentifier = pid_t(window.ownerPid.rawValue)
    let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
    let app = AppAccessibilityElement(processIdentifier)

    if let runningApplication {
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

    skipNextApplicationChange = true
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
