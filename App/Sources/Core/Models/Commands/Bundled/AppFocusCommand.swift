import AppKit
import Apps
import Foundation
import Windows

struct AppFocusCommand: Identifiable, Codable, Hashable {
  typealias Tiling = WorkspaceCommand.Tiling
  var id: String
  var bundleIdentifer: String
  var hideOtherApps: Bool
  var createNewWindow: Bool
  var tiling: Tiling?

  init(id: String = UUID().uuidString, bundleIdentifer: String,
       hideOtherApps: Bool, tiling: Tiling?,
       createNewWindow: Bool = true) {
    self.id = id
    self.bundleIdentifer = bundleIdentifer
    self.hideOtherApps = hideOtherApps
    self.createNewWindow = createNewWindow
    self.tiling = tiling
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.bundleIdentifer = try container.decode(String.self, forKey: .bundleIdentifer)
    self.hideOtherApps = try container.decode(Bool.self, forKey: .hideOtherApps)
    self.createNewWindow = try container.decodeIfPresent(Bool.self, forKey: .createNewWindow) ?? true
    self.tiling = try container.decodeIfPresent(AppFocusCommand.Tiling.self, forKey: .tiling)
  }

  @MainActor
  func commands(_ applications: [Application]) async throws -> [Command] {
    let aerospaceIsRunning = NSWorkspace.shared.runningApplications
      .first(where: { $0.bundleIdentifier == "bobko.aerospace" })
    != nil

    var commands = [Command]()
    let application: Application
    let bundleIdentifer: String
    let isCurrentApp = self.bundleIdentifer == Application.currentAppBundleIdentifier()

    if isCurrentApp {
      application = UserSpace.shared.frontmostApplication.asApplication()
      bundleIdentifer = application.bundleIdentifier
    } else if let resolvedApp = applications.first(where: { $0.bundleIdentifier == self.bundleIdentifer }) {
      application = resolvedApp
      bundleIdentifer = self.bundleIdentifer
    } else {
      return []
    }

    let allWindows = indexWindowsInStage(getWindows())
    var appWindows = allWindows.filter({ $0.ownerName == application.bundleName })
    var numberOfAppWindows = appWindows.count
    var runningApplication = NSWorkspace.shared.runningApplications.first(where: {
      $0.bundleIdentifier == bundleIdentifer
    })

    if createNewWindow && isCurrentApp || numberOfAppWindows == 0 {
      NSWorkspace.shared.open(URL(fileURLWithPath: application.path))
    }

    runningApplication?.activate(options: .activateAllWindows)


    var waitingForActivation: Bool = true
    var timeout: TimeInterval = 0

    if !isCurrentApp {
      while waitingForActivation {
        try Task.checkCancellation()
        if timeout > 10 { waitingForActivation = false }
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifer {
          waitingForActivation = false
          if runningApplication == nil {
            try? await Task.sleep(for: .milliseconds(100))
          }
        }
        timeout += 1
        try? await Task.sleep(for: .milliseconds(100))
      }
    }

    runningApplication = NSWorkspace.shared.frontmostApplication

    var waitingForWindow: Bool = true
    timeout = 0
    while waitingForWindow {
      try Task.checkCancellation()
      let allWindows = indexWindowsInStage(getWindows())
      appWindows = allWindows.filter({ Int32($0.ownerPid.rawValue) == runningApplication?.processIdentifier })
      numberOfAppWindows = appWindows.count

      if numberOfAppWindows > 0 {
        waitingForWindow = false
        break
      }

      try? await Task.sleep(for: .milliseconds(100))
      timeout += 1

      if timeout > 10 {
        waitingForWindow = false
      }
    }

    if numberOfAppWindows == 0 { return [] }

    if hideOtherApps && !aerospaceIsRunning {
      try await SystemHideAllAppsRunner.run(workflowCommands: [
        .application(.init(action: .open, application: application, meta: Command.MetaData(delay: nil, name: "Hide All Apps"), modifiers: []))
      ])
    }

    let windowTiling: WindowTiling?
    switch tiling {
    case .arrangeLeftRight:
      windowTiling = numberOfAppWindows > 2 ? .arrangeLeftRight : .fill
    case .arrangeRightLeft:
      windowTiling = numberOfAppWindows > 2 ? .arrangeRightLeft : .fill
    case .arrangeTopBottom:
      windowTiling = numberOfAppWindows > 2 ? .arrangeTopBottom : .fill
    case .arrangeBottomTop:
      windowTiling = numberOfAppWindows > 2 ? .arrangeBottomTop : .fill
    case .arrangeLeftQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .arrangeLeftQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .arrangeLeftRight
      } else {
        windowTiling = .fill
      }
    case .arrangeRightQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .arrangeRightQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .arrangeRightQuarters
      } else {
        windowTiling = .fill
      }
    case .arrangeTopQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .arrangeTopQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .arrangeTopBottom
      } else {
        windowTiling = .fill
      }
    case .arrangeBottomQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .arrangeBottomQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .arrangeBottomTop
      } else {
        windowTiling = .fill
      }
    case .arrangeQuarters:
      if numberOfAppWindows >= 4 {
        windowTiling = .arrangeQuarters
      } else if numberOfAppWindows == 3 {
        windowTiling = .arrangeLeftQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .arrangeLeftRight
      } else {
        windowTiling = .fill
      }
    case .arrangeDynamicQuarters:
      if let window = appWindows.first,
         let screen = NSScreen.screens.first(where: { $0.visibleFrame.mainDisplayFlipped.intersects(window.rect) }) {
        let leftTilings = [WindowTiling.left, .topLeft, .bottomLeft, .fill]
        let currentTiling = WindowTilingRunner.calculateTiling(for: window.rect, in: screen.visibleFrame.mainDisplayFlipped)

        if numberOfAppWindows >= 3 {
          if currentTiling == .left {
            windowTiling = .arrangeLeftQuarters
          } else if currentTiling == .right {
            windowTiling = .arrangeRightQuarters
          } else {
            windowTiling = leftTilings.contains(currentTiling) ? .arrangeLeftQuarters : .arrangeRightQuarters
          }
        } else if numberOfAppWindows == 2 {
          windowTiling = leftTilings.contains(currentTiling) ? .arrangeLeftRight : .arrangeRightLeft
        } else {
          windowTiling = .fill
        }
      } else {
        windowTiling = .fill
      }
    case .fill:
      windowTiling = .fill
    case .center:
      windowTiling = .center
    case nil:
      windowTiling = nil
    }

    if let windowTiling, !aerospaceIsRunning {
      commands.append(
        .windowTiling(.init(kind: windowTiling, meta: Command.MetaData(name: "Window Tiling")))
      )
    }

    return commands
  }

  private func getWindows() -> [WindowModel] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private func indexWindowsInStage(_ models: [WindowModel]) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 200)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
        $0.ownerName != "borders" &&
        $0.isOnScreen &&
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName)
      }

    return windows
  }

  func copy() -> Self {
    AppFocusCommand(
      id: UUID().uuidString,
      bundleIdentifer: self.bundleIdentifer,
      hideOtherApps: self.hideOtherApps,
      tiling: self.tiling,
      createNewWindow: self.createNewWindow
    )
  }
}
