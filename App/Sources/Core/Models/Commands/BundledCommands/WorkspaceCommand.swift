import Apps
import Cocoa
import Foundation
import Windows

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
    case arrangeDynamicQuarters
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
  func commands(_ applications: [Application]) async throws -> [Command] {
    var commands = [Command]()

    let slowBundles = Set(["com.tinyspeck.slackmacgap"])
    let bundleIdentifiersCount = bundleIdentifiers.count
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let windows = indexWindowsInStage(getWindows())

    let pids = windows.map(\.ownerPid.rawValue).map(Int32.init)
    let runningApplications = NSWorkspace.shared.runningApplications.filter({
      pids.contains($0.processIdentifier)
    })

    let runningTargetApps: [Int] = runningApplications
      .compactMap {
        guard let bundleIdentifier = $0.bundleIdentifier,
              bundleIdentifiers.contains(bundleIdentifier) else { return nil }
        return Int($0.processIdentifier)
      }
    let windowPids = windows.prefix(runningTargetApps.count)
      .map { $0.ownerPid.rawValue }

    let perfectBundleMatch = Set(runningTargetApps) == Set(windowPids)
    let hideAllAppsCommand = Command.systemCommand(SystemCommand(kind: .hideAllApps, meta: Command.MetaData(delay: nil, name: "Hide All Apps")))

    for (offset, bundleIdentifier) in bundleIdentifiers.enumerated() {
      try Task.checkCancellation()

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
      let name: String

      if let runningApplication, !windows.map(\.ownerPid.rawValue).contains(Int(runningApplication.processIdentifier)) {
        action = .open
        name = "Open \(application.displayName)"
      } else {
        if offset < runningApplications.count - 1,
           let runningApplication,
           runningApplication.processIdentifier == windows[offset].ownerPid.rawValue {
          action = .unhide
          name = "Fallback open/unhide \(application.displayName)"
        } else {
          action = .open
          name = "Open \(application.displayName)"
        }
      }

      if isLastItem {
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))

        if hideOtherApps {
          if !perfectBundleMatch || windowPids.isEmpty || runningTargetApps.isEmpty {
            commands.append(hideAllAppsCommand)
          }
        }

        let activationDelay: Double?

        if slowBundles.contains(application.bundleIdentifier) || application.metadata.isElectron {
          activationDelay = 225
        } else if perfectBundleMatch {
          activationDelay = nil
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
            meta: Command.MetaData(delay: nil, name: name), modifiers: [.waitForAppToLaunch]
          )))
      }
    }

    let windowTiling: SystemCommand.Kind? = switch tiling {
    case .arrangeLeftRight:       .windowTilingArrangeLeftRight
    case .arrangeRightLeft:       .windowTilingArrangeLeftRight
    case .arrangeTopBottom:       .windowTilingArrangeTopBottom
    case .arrangeBottomTop:       .windowTilingArrangeBottomTop
    case .arrangeLeftQuarters:    .windowTilingArrangeLeftQuarters
    case .arrangeRightQuarters:   .windowTilingArrangeRightQuarters
    case .arrangeTopQuarters:     .windowTilingArrangeTopQuarters
    case .arrangeBottomQuarters:  .windowTilingArrangeBottomQuarters
    case .arrangeDynamicQuarters: .windowTilingArrangeDynamicQuarters
    case .arrangeQuarters:        .windowTilingArrangeQuarters
    case .fill:                   .windowTilingFill
    case .center:                 .windowTilingCenter
    case nil:                     nil
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
}
