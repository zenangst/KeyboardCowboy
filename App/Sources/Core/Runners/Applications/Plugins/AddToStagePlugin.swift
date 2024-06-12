import Apps
import AXEssibility
import Carbon
import Cocoa
import Windows

enum AddToStagePluginError: Error {
  case windowNotFound
}

final class AddToStagePlugin {
  func execute(_ command: ApplicationCommand) async throws -> Bool {
    var snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)

    // Check if the application is already running.
    if Self.resolveRunningApplication(command.application) == nil {
      try await Self.activateTargetApplication(command)
      try await Self.activateCurrentApplication(snapshot)

      _ = try await Task(timeout: 5) {
        var result: Bool = false
        while result == false {
          if Self.resolveRunningApplication(command.application) != nil {
            result = true
          }
          try await Task.sleep(for: .milliseconds(100))
        }
        return result
      }.value

      try await Self.activateCurrentApplication(snapshot)
      snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    }

    guard let runningApplication = Self.resolveRunningApplication(command.application) else {
      return false
    }

    if runningApplication.isHidden {
      _ = runningApplication.unhide()
      _ = try await Task(timeout: 1) {
        while runningApplication.isHidden {
          try await Task.sleep(for: .milliseconds(100))
        }
        return true
      }.value
      snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    }

    let app = AppAccessibilityElement(runningApplication.processIdentifier)
    var axWindow = try app.windows().first(where: { ($0.frame?.height ?? 0) > 20 })

    if axWindow == nil {
      try await Self.activateTargetApplication(command)
      try await Self.activateCurrentApplication(snapshot)
      let newWindow = try await Task(timeout: 2) {
        var window: WindowAccessibilityElement?
        while window == nil {
          window = try? app.windows().first(where: { ($0.frame?.height ?? 0) > 20 })
        }
        return window
      }.value

      guard let newWindow else { return false }

      axWindow = newWindow
      try await Self.activateCurrentApplication(snapshot)
      try await Task.sleep(for: .seconds(1))
      await snapshot = UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    }

    guard let axWindow, var window = Self.resolveWindow(withId: axWindow.id, snapshot: snapshot) else { return false }

    let isInStage = axWindow.frame == window.rect

    if isInStage {
      return false
    }

    let mouseLocation = CGEvent(source: nil)?.location
    if window.rect.origin.x < 0 {
      window = try await Self.findWindowOnLeft(window, axWindow: axWindow, snapshot: &snapshot)
    } else if window.rect.origin.x + window.rect.width > NSScreen.main!.frame.size.width {
      window = try await Self.findWindowOnRight(window, axWindow: axWindow, snapshot: &snapshot)
    }

    Self.performClick(on: window, mouseDown: .leftMouseDown,
                      mouseUp: .leftMouseUp, withFlags: .maskShift)

    axWindow.isMinimized = false
    axWindow.performAction(.raise)

    if let mouseLocation {
      let restoreMouse = CGEvent(
        mouseEventSource: nil,
        mouseType: .mouseMoved,
        mouseCursorPosition: mouseLocation,
        mouseButton: .left
      )
      restoreMouse?.post(tap: .cghidEventTap)
    }

    return true
  }

  static func activateCurrentApplication(_ snapshot: UserSpace.Snapshot) async throws {
    let configuration = NSWorkspace.OpenConfiguration()
    let url = URL(fileURLWithPath: snapshot.frontMostApplication.asApplication().path)
    _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    snapshot.frontMostApplication.ref.activate(options: .activateIgnoringOtherApps)
  }

  static func activateTargetApplication(_ command: ApplicationCommand) async throws {
    let configuration = NSWorkspace.OpenConfiguration()
    let url = URL(fileURLWithPath: command.application.path)
    _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
  }

  static func performClick(on window: WindowModel, mouseDown: CGEventType, mouseUp: CGEventType, withFlags flags: CGEventFlags?) {
    let mouseEventDown = CGEvent(
      mouseEventSource: nil,
      mouseType: mouseDown,
      mouseCursorPosition: CGPoint(
        x: window.rect.origin.x + window.rect.width / 2,
        y: window.rect.origin.y + window.rect.height / 2
      ),
      mouseButton: .center
    )
    if let flags {
      mouseEventDown?.flags.insert(flags)
    }
    mouseEventDown?.setIntegerValueField(.mouseEventClickState, value: 1)
    mouseEventDown?.post(tap: .cghidEventTap)

    let mouseEventUp = CGEvent(
      mouseEventSource: nil,
      mouseType: mouseUp,
      mouseCursorPosition: CGPoint(
        x: window.rect.origin.x + window.rect.width / 2,
        y: window.rect.origin.y + window.rect.height / 2
      ),
      mouseButton: .center
    )
    if let flags {
      mouseEventUp?.flags.insert(flags)
    }
    mouseEventUp?.post(tap: .cghidEventTap)
  }

  static func findWindowOnLeft(_ window: WindowModel, axWindow: WindowAccessibilityElement, 
                               snapshot: inout UserSpace.Snapshot) async throws -> WindowModel {
    let moveMouse = CGEvent(
      mouseEventSource: nil,
      mouseType: .mouseMoved,
      mouseCursorPosition: CGPoint(
        x: 0,
        y: window.rect.origin.y + window.rect.height / 2
      ),
      mouseButton: .center
    )
    moveMouse?.post(tap: .cghidEventTap)
    try await Task.sleep(for: .milliseconds(175))

    snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)

    guard let resolvedWindow = resolveWindow(withId: axWindow.id, snapshot: snapshot) else {
      throw AddToStagePluginError.windowNotFound
    }
    return resolvedWindow
  }

  static func findWindowOnRight(_ window: WindowModel, axWindow: WindowAccessibilityElement, 
                                snapshot: inout UserSpace.Snapshot) async throws -> WindowModel {
    CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: 9999, y: window.rect.origin.y + window.rect.height / 2),
            mouseButton: .center
    )?.post(tap: .cghidEventTap)
    try await Task.sleep(for: .milliseconds(175))
    snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
    guard let resolvedWindow = resolveWindow(withId: axWindow.id, snapshot: snapshot) else { 
      throw AddToStagePluginError.windowNotFound
    }
    return resolvedWindow
  }

  static func resolveWindow(withId id: CGWindowID, snapshot: UserSpace.Snapshot) -> Windows.WindowModel? {
    snapshot.windows.visibleWindowsInSpace.first(where: { $0.id == id })
  }

  static func resolveRunningApplication(_ application: Application) -> NSRunningApplication? {
    return NSWorkspace.shared.runningApplications.first(where: { runningApplication in
      runningApplication.bundleIdentifier == application.bundleIdentifier &&
      runningApplication.isFinishedLaunching
    })
  }
}
