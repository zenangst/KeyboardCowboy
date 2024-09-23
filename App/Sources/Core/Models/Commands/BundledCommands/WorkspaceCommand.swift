import Apps
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

    var id: String { self.rawValue }
  }

  var id: String
  var bundleIdentifiers: [String]
  var tiling: Tiling?
  var hideOtherApps: Bool

  init(id: String = UUID().uuidString,
       bundleIdentifiers: [String],
       hideOtherApps: Bool = false,
       tiling: Tiling?) {
    self.id = id
    self.bundleIdentifiers = bundleIdentifiers
    self.hideOtherApps = hideOtherApps
    self.tiling = tiling
  }

  func commands(_ applications: [Application]) -> [Command] {
    var commands = [Command]()

    let hideAllAppsCommand = Command.systemCommand(SystemCommand(kind: .hideAllApps, meta: Command.MetaData(name: "Hide All Apps")))

    if hideOtherApps {
      commands.append(hideAllAppsCommand)
    }

    bundleIdentifiers.forEach { bundleIdentifier in
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        return
      }

      commands.append(
        .application(ApplicationCommand(
          action: .open,
          application: application,
          meta: Command.MetaData(name: "Open \(application.displayName)"),
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
    case nil:                    nil
    }

    if let kind {
      commands.append(.systemCommand(SystemCommand(kind: kind, meta: Command.MetaData(name: "Tiling Command"))))
    }

    if hideOtherApps {
      commands.append(hideAllAppsCommand)
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
