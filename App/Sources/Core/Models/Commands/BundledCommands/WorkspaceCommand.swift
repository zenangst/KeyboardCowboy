import Apps
import Cocoa
import Foundation

struct WorkspaceCommand: Identifiable, Codable, Hashable {
  enum Tiling: String, Codable, CaseIterable, Identifiable {
    case arrangeLeftRight
    case arrangeRightLeft
    case arrangeTopBottom
    case arrangeBottomTop
    case arrangeLeftQuarters
    case arrangeRightQuarters
    case arrangeTopQuarters
    case arrangeBottomQuarters
    case arrangeQuarters
    case fill
    case center

    var id: String { self.rawValue }
  }

  var id: String
  var bundleIdentifiers: [String]
  var tiling: Tiling?
  var hideOtherApps: Bool

  init(id: String = UUID().uuidString,
       bundleIdentifiers: [String],
       hideOtherApps: Bool,
       tiling: Tiling?) {
    self.id = id
    self.bundleIdentifiers = bundleIdentifiers
    self.hideOtherApps = hideOtherApps
    self.tiling = tiling
  }

  func commands(_ applications: [Application]) -> [Command] {
    var commands = [Command]()

    let slowBundles = Set(["com.apple.dt.Xcode"])
    let hideDelay: TimeInterval?

    if slowBundles.intersection(bundleIdentifiers).count > 0 {
      hideDelay = 100
    } else {
      hideDelay = nil
    }

    let hideAllAppsCommand = Command.systemCommand(SystemCommand(kind: .hideAllApps, meta: Command.MetaData(delay: hideDelay, name: "Hide All Apps")))
    let bundleIdentifiersCount = bundleIdentifiers.count

    bundleIdentifiers.enumerated().forEach { offset, bundleIdentifier in
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        return
      }

      let appIsRunning = NSWorkspace.shared.runningApplications.first(where: { app in
        guard let bundleIdentifier = app.bundleIdentifier else { return false }
        return bundleIdentifiers.contains(bundleIdentifier) == true
      }) != nil

      let delay: TimeInterval?
      if bundleIdentifiersCount - 1 == offset {
        delay = 50
      } else if !appIsRunning {
        delay = 150
      } else {
        delay = nil
      }

      commands.append(
        .application(ApplicationCommand(
          action: .open,
          application: application,
          meta: Command.MetaData(delay: delay, name: "Open \(application.displayName)"),
          modifiers: [.waitForAppToLaunch]
        )))
    }

    let kind: SystemCommand.Kind? = switch tiling {
    case .arrangeLeftRight:      .windowTilingArrangeLeftRight
    case .arrangeRightLeft:      .windowTilingArrangeRightLeft
    case .arrangeTopBottom:      .windowTilingArrangeTopBottom
    case .arrangeBottomTop:      .windowTilingArrangeBottomTop
    case .arrangeLeftQuarters:   .windowTilingArrangeLeftQuarters
    case .arrangeRightQuarters:  .windowTilingArrangeRightQuarters
    case .arrangeTopQuarters:    .windowTilingArrangeTopQuarters
    case .arrangeBottomQuarters: .windowTilingArrangeBottomQuarters
    case .arrangeQuarters:       .windowTilingArrangeQuarters
    case .fill:                  .windowTilingFill
    case .center:                .windowTilingCenter
    case nil:                    nil
    }

    if hideOtherApps {
      commands.append(hideAllAppsCommand)
    }

    if let kind {
      if case .windowTilingFill = kind {
        commands.append(.menuBar(MenuBarCommand(application: nil, tokens: [.menuItem(name: "Window"), .menuItem(name: "Fill")],
                                                meta: Command.MetaData(name: "MenuBarCommand"))))
      } else if case .windowTilingCenter = kind {
        commands.append(.menuBar(MenuBarCommand(application: nil, tokens: [.menuItem(name: "Window"), .menuItem(name: "Center")],
                                                meta: Command.MetaData(name: "MenuBarCommand"))))

      } else {
        commands.append(.systemCommand(SystemCommand(kind: kind, meta: Command.MetaData(name: "Tiling Command"))))
      }
    }

    return commands
  }

  func copy() -> WorkspaceCommand {
    WorkspaceCommand(
      id: UUID().uuidString,
      bundleIdentifiers: bundleIdentifiers,
      hideOtherApps: hideOtherApps,
      tiling: tiling
    )
  }
}
