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

    let slowBundles = Set(["com.tinyspeck.slackmacgap"])
    let bundleIdentifiersCount = bundleIdentifiers.count
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let windows = WindowStore.shared.windows

    let pids = windows.map(\.ownerPid.rawValue).map(Int32.init)
    let runningApplications = NSWorkspace.shared.runningApplications.filter({
      pids.contains($0.processIdentifier)
    })
    let runningBundles = Set(runningApplications.compactMap(\.bundleIdentifier))
    let perfectBundleMatch = runningBundles == Set(bundleIdentifiers)

    let hideDelay: Double?
    if perfectBundleMatch {
      hideDelay = nil
    } else {
      hideDelay = 175
    }

    let hideAllAppsCommand = Command.systemCommand(SystemCommand(kind: .hideAllApps, meta: Command.MetaData(delay: hideDelay, name: "Hide All Apps")))

    for (offset, bundleIdentifier) in bundleIdentifiers.enumerated() {
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        continue
      }

      let runningApplication = NSWorkspace.shared.runningApplications.first(where: { app in
        guard let bundleIdentifier = app.bundleIdentifier else { return false }
        return application.bundleIdentifier == bundleIdentifier
      })

      let appIsRunning = runningApplication != nil
      let isFrontmost = frontmostApplication?.bundleIdentifier == bundleIdentifier
      let isLastItem = bundleIdentifiersCount - 1 == offset
      let action: ApplicationCommand.Action

      if let runningApplication, !windows.map(\.ownerPid.rawValue).contains(Int(runningApplication.processIdentifier)) {
        action = .open
      } else {
        action = .unhide
      }

      if isLastItem {
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))

        if hideOtherApps && !perfectBundleMatch { commands.append(hideAllAppsCommand) }

        let activationDelay: Double?

        if perfectBundleMatch {
          activationDelay = nil
        } else if !perfectBundleMatch {
          activationDelay = hideDelay != nil ? nil : 200
        } else if slowBundles.contains(application.bundleIdentifier) {
          activationDelay = 225
        } else {
          activationDelay = 25
        }

        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: activationDelay, name: "Activate \(application.displayName)"),
            modifiers: []
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
            meta: Command.MetaData(delay: 250, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      } else {
        commands.append(
          .application(ApplicationCommand(
            action: action,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Fallback open/unhide \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      }
    }

    let windowTiling: SystemCommand.Kind? = switch tiling {
    case .arrangeLeftRight:      .windowTilingArrangeLeftRight
    case .arrangeRightLeft:      .windowTilingArrangeLeftRight
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

    if let windowTiling {
      commands.append(
        .systemCommand(.init(kind: windowTiling, meta: Command.MetaData(name: "Window Tiling")))
      )
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
