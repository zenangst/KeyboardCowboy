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

  @MainActor
  func commands(_ applications: [Application]) -> [Command] {
    var commands = [Command]()

    let hideAllAppsCommand = Command.systemCommand(SystemCommand(kind: .hideAllApps, meta: Command.MetaData(delay: nil, name: "Hide All Apps")))
    let bundleIdentifiersCount = bundleIdentifiers.count
    let frontmostApplication = NSWorkspace.shared.frontmostApplication

    bundleIdentifiers.enumerated().forEach { offset, bundleIdentifier in
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        return
      }

      let runningApplication = NSWorkspace.shared.runningApplications.first(where: { app in
        guard let bundleIdentifier = app.bundleIdentifier else { return false }
        return application.bundleIdentifier == bundleIdentifier
      })

      let appIsRunning = runningApplication != nil
      let isFrontmost = frontmostApplication?.bundleIdentifier == bundleIdentifier
      let isLastItem = bundleIdentifiersCount - 1 == offset

      if hideOtherApps { commands.append(hideAllAppsCommand) }

      if isLastItem {
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: 25, name: "Activate \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      } else if isFrontmost {
        commands.append(
          .application(ApplicationCommand(
            action: .unhide,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Unhide frontmost application \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      } else if !appIsRunning {
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      } else {
        commands.append(
          .application(ApplicationCommand(
            action: .unhide,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Unhide \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      }
    }


    let tokens: [MenuBarCommand.Token] = switch tiling {
    case .arrangeLeftRight:      MenuBarCommand.Token.leftRight()
    case .arrangeRightLeft:      MenuBarCommand.Token.rightLeft()
    case .arrangeTopBottom:      MenuBarCommand.Token.topBottom()
    case .arrangeBottomTop:      MenuBarCommand.Token.bottomTop()
    case .arrangeLeftQuarters:   MenuBarCommand.Token.leftQuarters()
    case .arrangeRightQuarters:  MenuBarCommand.Token.rightQuarters()
    case .arrangeTopQuarters:    MenuBarCommand.Token.topQuarters()
    case .arrangeBottomQuarters: MenuBarCommand.Token.bottomQuarters()
    case .arrangeQuarters:       MenuBarCommand.Token.quarters()
    case .fill:                  MenuBarCommand.Token.fill()
    case .center:                MenuBarCommand.Token.center()
    case nil:                    []
    }

    if !tokens.isEmpty {
      commands.append(.menuBar(.init(application: nil, tokens: tokens, meta: Command.MetaData(name: "MenuBarCommand"))))
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
