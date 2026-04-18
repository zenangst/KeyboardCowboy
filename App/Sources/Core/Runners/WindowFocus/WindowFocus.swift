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
  static var pendingFocusWindowId: CGWindowID?
  static var currentWindow: WindowModel?

  static func frontMostApplicationChanged() {
    updateRings()
  }

  static func updateRings(_ windowId: CGWindowID? = nil) {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else { return }

    let newAppWindows = WindowStore.shared
      .getWindows(onScreen: true)
      .filter { $0.ownerPid.rawValue == frontmostApplication.processIdentifier }

    appRing.update(newAppWindows)

    let processIdentifier = frontmostApplication.processIdentifier
    let app = AppAccessibilityElement(processIdentifier)

    let id: CGWindowID
    if let windowId {
      id = windowId
    } else if let resolvedId = try? app.focusedWindow()?.id {
      id = resolvedId
    } else {
      return
    }

    guard let window = newAppWindows.first(where: { $0.id == id }) else { return }

    currentWindow = window

    if pendingFocusWindowId == id {
      appRing.setCursor(to: window)
      globalRing.setCursor(to: window)
      stageRing.setCursor(to: window)
      pendingFocusWindowId = nil
    } else {
      appRing.moveEntryToCursor(window)
      globalRing.moveEntryToCursor(window)
      stageRing.moveEntryToCursor(window)
    }
  }

  static func run(kind: WindowFocusCommand.Kind, applicationStore: ApplicationStore,
                  workspace: WorkspaceProviding) async throws {
    let newCollection: [WindowModel]
    let ring: RingBuffer<WindowModel>
    let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true).windows

    if kind == .moveFocusToNextWindowFront || kind == .moveFocusToPreviousWindowFront {
      newCollection = snapshot.visibleWindowsInSpace
        .filter { $0.ownerPid.rawValue == UserSpace.shared.frontmostApplication.ref.processIdentifier }
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

    guard !newCollection.isEmpty else { return }
    syncCursor(with: newCollection, in: ring)

    guard let nextWindow = ring.navigate(direction, entries: newCollection) else {
      return
    }

    let windowId = UInt32(nextWindow.id)
    let processIdentifier = pid_t(nextWindow.ownerPid.rawValue)
    let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
    let app = AppAccessibilityElement(processIdentifier)
    let axWindow = try app.windows().first(where: { $0.id == windowId })

    pendingFocusWindowId = windowId

    if let runningApplication {
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

    axWindow?.main = true
    axWindow?.performAction(.raise)
  }

  private static func syncCursor(with windows: [WindowModel], in ring: RingBuffer<WindowModel>) {
    ring.update(windows)

    guard let focusedWindow = focusedWindow(in: windows) else { return }

    ring.setCursor(to: focusedWindow)
  }

  private static func focusedWindow(in windows: [WindowModel]) -> WindowModel? {
    if let frontmostApplication = NSWorkspace.shared.frontmostApplication {
      let app = AppAccessibilityElement(frontmostApplication.processIdentifier)

      if let id = try? app.focusedWindow()?.id,
         let window = windows.first(where: { $0.id == id }) {
        return window
      }

      if let currentWindow,
         let window = windows.first(where: { $0.id == currentWindow.id }) {
        return window
      }

      return windows.first(where: { $0.ownerPid.rawValue == frontmostApplication.processIdentifier })
    }

    if let currentWindow {
      return windows.first(where: { $0.id == currentWindow.id })
    }

    return nil
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
