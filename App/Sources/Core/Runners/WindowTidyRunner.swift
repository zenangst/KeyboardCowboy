import AXEssibility
import Cocoa
import Windows

@MainActor
final class WindowTidyRunner: Sendable {
  static var debug: Bool = false

  func run(_ command: WindowTidyCommand) async throws {
    let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)

    guard let screen = NSScreen.main else { return }

    let visibleScreenFrame = screen.visibleFrame.mainDisplayFlipped
    let windows = snapshot.windows
      .visibleWindowsInStage
      .filter { $0.rect.intersects(visibleScreenFrame) }
    guard !windows.isEmpty else { return }

    let apps: [WindowModel.Pid] = windows.reduce(into: (result: [], set: Set<Int>())) { ctx, window in
      if ctx.set.insert(window.ownerPid.rawValue).inserted {
        ctx.result.append(window.ownerPid)
      }
    }.result

    if apps.count == 1 {
      let pid = pid_t(apps[0].rawValue)
      await singleApp(pid, windows: windows, visibleScreenFrame: visibleScreenFrame, snapshot: snapshot)
    } else {
      await multipleApps(rules: command.rules, windows: windows,
                         visibleScreenFrame: visibleScreenFrame,
                         snapshot: snapshot)
    }
  }

  private func singleApp(_ pid: pid_t, windows: [WindowModel], visibleScreenFrame: CGRect, snapshot _: UserSpace.Snapshot) async {
    let axApp = AppAccessibilityElement(pid)
    let currentWindow = windows[0]
    let count = windows.count
    let tilings: [WindowTiling]
    let determinedCurrentTiling = WindowTilingRunner.calculateTiling(
      for: currentWindow.rect,
      ownerName: currentWindow.ownerName,
      in: visibleScreenFrame,
    )

    var windows = Array(windows.reversed())

    if count == 1 {
      tilings = [.fill]
    } else if count == 2 {
      tilings = switch determinedCurrentTiling {
      case .right, .topRight, .bottomRight, .bottom:
        [.arrangeRightLeft]
      default:
        [.arrangeLeftRight]
      }
      windows.removeFirst()
    } else if count == 3 {
      let selectedTiling: WindowTiling = switch determinedCurrentTiling {
      case .right, .topRight, .bottomRight, .bottom:
        .arrangeRightQuarters
      default:
        .arrangeLeftQuarters
      }

      windows = [windows.last!]
      tilings = [selectedTiling]
    } else {
      let rightTiles: Set<WindowTiling> = [.right, .topRight, .bottomRight, .bottom]
      let selectedTiling: WindowTiling = rightTiles.contains(determinedCurrentTiling) ? .right : .left
      var computedTilings: [WindowTiling] = Array(repeating: selectedTiling == .left ? .bottomRight : .bottomLeft, count: windows.count)
      for (offset, window) in windows.enumerated() {
        let determinedTiling = WindowTilingRunner.calculateTiling(
          for: window.rect,
          ownerName: window.ownerName,
          in: visibleScreenFrame,
        )

        if currentWindow == window {
          computedTilings[offset] = selectedTiling
        } else if selectedTiling == .left {
          if determinedTiling == .right {
            computedTilings[offset] = .topRight
          } else if rightTiles.contains(determinedTiling) {
            computedTilings[offset] = determinedTiling
          } else {
            computedTilings[offset] = determinedTiling.revesed
          }
        } else {
          if determinedTiling == .right {
            computedTilings[offset] = .topLeft
          } else if !rightTiles.contains(determinedTiling) {
            computedTilings[offset] = determinedTiling
          } else {
            computedTilings[offset] = determinedTiling.revesed
          }
        }
      }

      tilings = computedTilings
    }

    var menuItems = [MenuBarItemAccessibilityElement]()
    let windowSpacing = UserSettings.WindowManager.tiledWindowSpacing
    var shouldActivateLastWindow = false
    var lastAxWindow: WindowAccessibilityElement?
    for (offset, window) in windows.enumerated() {
      let tiling = tilings[offset]

      guard let axWindow = try? axApp
        .windows()
        .first(where: { $0.id == window.id })
      else {
        continue
      }

      if window == currentWindow {
        lastAxWindow = axWindow
      }

      if tiling != .fill, window.rect.isValid(for: tiling, window: window, in: visibleScreenFrame, spacing: windowSpacing) {
        continue
      }

      if count > 1 {
        axWindow.performAction(.raise)
      }

      if menuItems.isEmpty {
        guard let resolvedMenuItems = try? axApp
          .menuBar()
          .menuItems()
        else {
          return
        }

        menuItems = resolvedMenuItems
      }

      shouldActivateLastWindow = true

      let match = WindowTilingMenuItemFinder.find(tiling, in: menuItems)
      match?.performAction(.pick)
    }

    if shouldActivateLastWindow {
      lastAxWindow?.performAction(.raise)
    }
  }

  private func multipleApps(rules: [WindowTidyCommand.Rule], windows: [WindowModel],
                            visibleScreenFrame: CGRect, snapshot _: UserSpace.Snapshot) async
  {
    let currentWindow = windows[0]
    let windowSpacing = UserSettings.WindowManager.tiledWindowSpacing
    let activeWindows: [WindowModel] = windows.reversed()

    var apps: [Int: AppContainer] = [:]
    var shouldActivateLastWindow = false
    var lastAppContainer: AppContainer?
    var lastAxWindow: WindowAccessibilityElement?
    var quarterTiling: Set<WindowTiling> = [
      .topLeft, .bottomLeft,
      .topRight, .bottomRight,
    ]
    var occupiedTiling = Set<WindowTiling>()

    for window in activeWindows {
      let pid = pid_t(window.ownerPid.rawValue)
      let activeTiling: WindowTiling
      if let runningApplication = NSRunningApplication(processIdentifier: pid),
         let bundleIdentifier = runningApplication.bundleIdentifier,
         let rule = rules.first(where: { $0.bundleIdentifier == bundleIdentifier })
      {
        activeTiling = rule.tiling
        quarterTiling.remove(activeTiling)

        if activeTiling == .left {
          quarterTiling.remove(.topLeft)
          quarterTiling.remove(.bottomLeft)
        } else if activeTiling == .right {
          quarterTiling.remove(.topRight)
          quarterTiling.remove(.bottomRight)
        }
      } else {
        activeTiling = WindowTilingRunner.calculateTiling(
          for: window.rect,
          ownerName: window.ownerName,
          in: visibleScreenFrame,
        )
      }

      occupiedTiling.insert(activeTiling)
    }

    var currentWindowTiling = WindowTilingRunner.calculateTiling(
      for: currentWindow.rect,
      ownerName: currentWindow.ownerName,
      in: visibleScreenFrame,
    )

    if currentWindowTiling != .left || currentWindowTiling != .right {
      currentWindowTiling = isLeftTiling(currentWindowTiling) ? .left : .right
    }

    updateOccupiedTiles(currentWindowTiling, occupiedTiling: &occupiedTiling)

    for (offset, window) in activeWindows.enumerated() {
      let appContainer: AppContainer

      if let resolvedAppContainer = apps[Int(window.ownerPid.rawValue)] {
        appContainer = resolvedAppContainer
      } else {
        let pid = pid_t(window.ownerPid.rawValue)
        let app = AppAccessibilityElement(pid)
        guard let runningApplication = NSRunningApplication(processIdentifier: pid) else { continue }

        appContainer = AppContainer(
          axElement: app,
          runningApplication: runningApplication,
        )
        apps[window.ownerPid.rawValue] = appContainer
      }

      guard let axWindow = try? appContainer.axElement
        .windows()
        .first(where: { $0.id == window.id })
      else {
        continue
      }

      let tiling: WindowTiling
      let calculatedTiling = WindowTilingRunner.calculateTiling(
        for: window.rect,
        ownerName: window.ownerName,
        in: visibleScreenFrame,
      )

      if activeWindows.count > 3, let rule = rules.first(where: { $0.bundleIdentifier == appContainer.runningApplication.bundleIdentifier }) {
        if offset == activeWindows.count - 2, occupiedTiling.contains(rule.tiling), !quarterTiling.isEmpty {
          let random = quarterTiling.randomElement()!
          quarterTiling.remove(random)
          tiling = random
        } else {
          tiling = rule.tiling
          quarterTiling.remove(tiling)
        }
        updateOccupiedTiles(tiling, occupiedTiling: &occupiedTiling)
      } else {
        // Force side-by-side
        if activeWindows.count == 2 {
          if window == currentWindow {
            tiling = currentWindowTiling
          } else {
            tiling = isLeftTiling(currentWindowTiling) ? .right : .left
          }
          // Make sure that at least one of the windows use left or right
        } else if activeWindows.count == 3 {
          if window == currentWindow {
            tiling = currentWindowTiling
          } else {
            let top = offset % 2 == 1
            tiling = isLeftTiling(currentWindowTiling)
              ? (top ? .topRight : .bottomRight)
              : (top ? .topLeft : .bottomLeft)
          }
        } else if !quarterTiling.isEmpty,
                  occupiedTiling.contains(calculatedTiling),
                  let random = quarterTiling.randomElement()
        {
          tiling = random
          quarterTiling.remove(random)
        } else {
          tiling = calculatedTiling
        }
      }

      lastAxWindow = axWindow
      lastAppContainer = appContainer

      if window.rect.isValid(for: tiling, window: window, in: visibleScreenFrame, spacing: windowSpacing) {
        continue
      }

      shouldActivateLastWindow = true

      appContainer.runningApplication.activate(options: .activateIgnoringOtherApps)
      if let bundleURL = appContainer.runningApplication.bundleURL {
        NSWorkspace.shared.open(URL(fileURLWithPath: bundleURL.path()))
      }
      axWindow.performAction(.raise)

      guard let menuItems = try? appContainer.axElement
        .menuBar()
        .menuItems()
      else {
        continue
      }
      guard let match = WindowTilingMenuItemFinder.find(tiling, in: menuItems) else {
        continue
      }

      match.performAction(.pick)
      try? await Task.sleep(for: .milliseconds(10))
    }

    if shouldActivateLastWindow, let appContainer = lastAppContainer {
      appContainer.runningApplication.activate(options: .activateIgnoringOtherApps)
      if let bundleURL = appContainer.runningApplication.bundleURL {
        NSWorkspace.shared.open(URL(fileURLWithPath: bundleURL.path()))
      }
      lastAxWindow?.performAction(.raise)
    }
  }

  func updateOccupiedTiles(_ tiling: WindowTiling, occupiedTiling: inout Set<WindowTiling>) {
    if tiling == .left {
      occupiedTiling.insert(.left)
      occupiedTiling.insert(.topLeft)
      occupiedTiling.insert(.bottomLeft)
    } else if tiling == .right {
      occupiedTiling.insert(.right)
      occupiedTiling.insert(.topRight)
      occupiedTiling.insert(.bottomRight)
    } else {
      occupiedTiling.insert(tiling)
    }
  }

  func isLeftTiling(_ tiling: WindowTiling) -> Bool {
    switch tiling {
    case .right, .topRight, .bottomRight, .bottom:
      false
    default:
      true
    }
  }
}

private class AppContainer {
  var axElement: AppAccessibilityElement
  var runningApplication: NSRunningApplication

  init(axElement: AppAccessibilityElement,
       runningApplication: NSRunningApplication)
  {
    self.axElement = axElement
    self.runningApplication = runningApplication
  }
}
