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
    var commands = [Command]()

    guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifer }) else {
      return []
    }

    let allWindows = indexWindowsInStage(getWindows())
    var numberOfAppWindows = allWindows.filter({ $0.ownerName == application.bundleName }).count
    var runningApplication = NSWorkspace.shared.runningApplications.first(where: {
      $0.bundleIdentifier == bundleIdentifer
    })

    if createNewWindow && numberOfAppWindows == 0 {
      NSWorkspace.shared.open(URL(fileURLWithPath: application.path))
    }
    runningApplication?.activate(options: .activateAllWindows)

    var waitingForActivation: Bool = true
    var timeout: TimeInterval = 0
    while waitingForActivation {
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

    runningApplication = NSWorkspace.shared.frontmostApplication

    var waitingForWindow: Bool = true
    timeout = 0
    while waitingForWindow {
      let allWindows = indexWindowsInStage(getWindows())
      numberOfAppWindows = allWindows.filter({ Int32($0.ownerPid.rawValue) == runningApplication?.processIdentifier }).count

      if numberOfAppWindows > 0 {
        waitingForWindow = false
      }

      try? await Task.sleep(for: .milliseconds(100))
      timeout += 1

      if timeout > 10 {
        waitingForWindow = false
      }
    }

    if numberOfAppWindows == 0 { return [] }

    if hideOtherApps {
      try await SystemHideAllAppsRunner.run(workflowCommands: [
        .application(.init(action: .open, application: application, meta: Command.MetaData(delay: nil, name: "Hide All Apps"), modifiers: []))
      ])
    }

    let windowTiling: SystemCommand.Kind?
    switch tiling {
    case .arrangeLeftRight:
      windowTiling = numberOfAppWindows > 2 ? .windowTilingArrangeLeftRight : .windowTilingFill
    case .arrangeRightLeft:
      windowTiling = numberOfAppWindows > 2 ? .windowTilingArrangeLeftRight : .windowTilingFill
    case .arrangeTopBottom:
      windowTiling = numberOfAppWindows > 2 ? .windowTilingArrangeTopBottom : .windowTilingFill
    case .arrangeBottomTop:
      windowTiling = numberOfAppWindows > 2 ? .windowTilingArrangeBottomTop : .windowTilingFill
    case .arrangeLeftQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .windowTilingArrangeLeftQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .windowTilingArrangeLeftRight
      } else {
        windowTiling = .windowTilingFill
      }
    case .arrangeRightQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .windowTilingArrangeRightQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .windowTilingArrangeLeftRight
      } else {
        windowTiling = .windowTilingFill
      }
    case .arrangeTopQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .windowTilingArrangeTopQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .windowTilingArrangeLeftRight
      } else {
        windowTiling = .windowTilingFill
      }
    case .arrangeBottomQuarters:
      if numberOfAppWindows >= 3 {
        windowTiling = .windowTilingArrangeBottomQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .windowTilingArrangeLeftRight
      } else {
        windowTiling = .windowTilingFill
      }
    case .arrangeQuarters:
      if numberOfAppWindows >= 4 {
        windowTiling = .windowTilingArrangeQuarters
      } else if numberOfAppWindows == 3 {
        windowTiling = .windowTilingArrangeLeftQuarters
      } else if numberOfAppWindows == 2 {
        windowTiling = .windowTilingArrangeLeftRight
      } else {
        windowTiling = .windowTilingFill
      }
    case .arrangeDynamicQuarters:
      windowTiling = .windowTilingArrangeDynamicQuarters
    case .fill:
      windowTiling = .windowTilingFill
    case .center:
      windowTiling = .windowTilingCenter
    case nil:
      windowTiling = nil
    }

    if let windowTiling {
      commands.append(
        .systemCommand(.init(kind: windowTiling, meta: Command.MetaData(name: "Window Tiling")))
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
        $0.ownerName != "Keyboard Cowboy" &&
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
