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
  static var previousWindowIds = [Ring: Int]()
  static var appRing = RingBuffer<WindowModel>()
  static var globalRing = RingBuffer<WindowModel>()
  static var stageRing = RingBuffer<WindowModel>()
  static var pendingFocusWindowId: CGWindowID?
  static var currentWindow: WindowModel?

  static func frontMostApplicationChanged() {
    updateRings()
  }

  static func handleActiveSpaceDidChange() {
    resetState()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      WindowStore.shared.index()
      WindowFocus.updateRings()
    }
  }

  static func updateRings(_ windowId: CGWindowID? = nil) {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else { return }

    let onScreenWindows = WindowStore.shared.getWindows(onScreen: true)
    let visibleWindowsInSpace = WindowStore.shared.allApplicationsInSpace(onScreenWindows, onScreen: true)
    let visibleWindowsInStage = WindowStore.shared.indexStage(onScreenWindows)

    let newAppWindows = onScreenWindows
      .filter { $0.ownerPid.rawValue == frontmostApplication.processIdentifier }

    appRing.update(newAppWindows)
    globalRing.update(visibleWindowsInSpace)
    stageRing.update(visibleWindowsInStage)

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

    updatePreviousWindowIds(
      previousWindowId: currentWindow?.id,
      previousOwnerPid: currentWindow.map { pid_t($0.ownerPid.rawValue) },
      currentWindowId: window.id,
      currentOwnerPid: pid_t(window.ownerPid.rawValue),
      appWindowIds: Set(newAppWindows.map(\.id)),
      stageWindowIds: Set(visibleWindowsInStage.map(\.id)),
      globalWindowIds: Set(visibleWindowsInSpace.map(\.id)),
    )

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
    let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true).windows
    guard let (newCollection, ringKind, ring) = collection(for: kind, snapshot: snapshot) else {
      return
    }
    guard !newCollection.isEmpty else { return }

    if isPrevious(kind),
       let previousWindow = previousWindow(in: newCollection, ring: ringKind) {
      try await focus(previousWindow, applicationStore: applicationStore, workspace: workspace)
      return
    }

    let direction: RingBufferDirection = switch kind {
    case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal, .moveFocusToNextWindowFront:
      .right
    default:
      .left
    }

    syncCursor(with: newCollection, in: ring)

    guard let nextWindow = ring.navigate(direction, entries: newCollection) else {
      return
    }

    try await focus(nextWindow, applicationStore: applicationStore, workspace: workspace)
  }

  static func updatePreviousWindowIds(previousWindowId: Int?,
                                      previousOwnerPid: pid_t?,
                                      currentWindowId: Int,
                                      currentOwnerPid: pid_t,
                                      appWindowIds: Set<Int>,
                                      stageWindowIds: Set<Int>,
                                      globalWindowIds: Set<Int>) {
    guard let previousWindowId,
          let previousOwnerPid,
          previousWindowId != currentWindowId else { return }

    if previousOwnerPid == currentOwnerPid,
       appWindowIds.contains(previousWindowId),
       appWindowIds.contains(currentWindowId) {
      previousWindowIds[.app] = previousWindowId
    } else {
      previousWindowIds[.app] = nil
    }

    if stageWindowIds.contains(previousWindowId),
       stageWindowIds.contains(currentWindowId) {
      previousWindowIds[.stage] = previousWindowId
    } else {
      previousWindowIds[.stage] = nil
    }

    if globalWindowIds.contains(previousWindowId),
       globalWindowIds.contains(currentWindowId) {
      previousWindowIds[.global] = previousWindowId
    } else {
      previousWindowIds[.global] = nil
    }
  }

  static func preferredPreviousWindowId(in availableWindowIds: Set<Int>,
                                        ring: Ring,
                                        currentWindowId: Int?) -> Int? {
    guard let previousWindowId = previousWindowIds[ring],
          previousWindowId != currentWindowId,
          availableWindowIds.contains(previousWindowId) else {
      if let previousWindowId = previousWindowIds[ring],
         !availableWindowIds.contains(previousWindowId) {
        previousWindowIds[ring] = nil
      }

      return nil
    }

    return previousWindowId
  }

  private static func focus(_ window: WindowModel,
                            applicationStore: ApplicationStore,
                            workspace: WorkspaceProviding) async throws {
    let windowId = UInt32(window.id)
    let processIdentifier = pid_t(window.ownerPid.rawValue)
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

  private static func collection(for kind: WindowFocusCommand.Kind,
                                 snapshot: WindowStoreSnapshot) -> ([WindowModel], Ring, RingBuffer<WindowModel>)? {
    if kind == .moveFocusToNextWindowFront || kind == .moveFocusToPreviousWindowFront {
      let windows = snapshot.visibleWindowsInSpace
        .filter { $0.ownerPid.rawValue == UserSpace.shared.frontmostApplication.ref.processIdentifier }
      return (windows, .app, appRing)
    } else if kind == .moveFocusToNextWindow || kind == .moveFocusToPreviousWindow {
      return (snapshot.visibleWindowsInStage, .stage, stageRing)
    } else if kind == .moveFocusToNextWindowGlobal || kind == .moveFocusToPreviousWindowGlobal {
      return (snapshot.visibleWindowsInSpace, .global, globalRing)
    } else {
      return nil
    }
  }

  private static func isPrevious(_ kind: WindowFocusCommand.Kind) -> Bool {
    switch kind {
    case .moveFocusToPreviousWindow,
         .moveFocusToPreviousWindowGlobal,
         .moveFocusToPreviousWindowFront:
      true
    default:
      false
    }
  }

  private static func previousWindow(in windows: [WindowModel], ring: Ring) -> WindowModel? {
    let currentWindowId = focusedWindow(in: windows)?.id ?? currentWindow?.id
    guard let previousWindowId = preferredPreviousWindowId(
      in: Set(windows.map(\.id)),
      ring: ring,
      currentWindowId: currentWindowId,
    ) else {
      return nil
    }

    return windows.first(where: { $0.id == previousWindowId })
  }

  private static func syncCursor(with windows: [WindowModel], in ring: RingBuffer<WindowModel>) {
    ring.update(windows)

    guard let focusedWindow = focusedWindow(in: windows) else { return }

    ring.setCursor(to: focusedWindow)
  }

  static func resetState() {
    visibleMostIndexByRing.removeAll()
    previousWindowIds.removeAll()
    appRing = RingBuffer<WindowModel>()
    globalRing = RingBuffer<WindowModel>()
    stageRing = RingBuffer<WindowModel>()
    pendingFocusWindowId = nil
    currentWindow = nil
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
