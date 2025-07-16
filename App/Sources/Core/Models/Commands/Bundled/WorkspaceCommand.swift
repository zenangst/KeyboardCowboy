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

  enum CodingKeys: CodingKey {
    case id
    case appToggleModifiers
    case bundleIdentifiers
    case defaultForDynamicWorkspace
    case hideOtherApps
    case tiling
  }

  var id: String
  var bundleIdentifiers: [String]
  var tiling: Tiling?
  var hideOtherApps: Bool
  var appToggleModifiers: [ModifierKey]

  var defaultForDynamicWorkspace: Bool
  var isDynamic: Bool { bundleIdentifiers.isEmpty }

  init(id: String = UUID().uuidString,
       assignmentModifierS: [ModifierKey] = [],
       appToggleModifiers: [ModifierKey] = [],
       bundleIdentifiers: [String],
       defaultForDynamicWorkspace: Bool,
       hideOtherApps: Bool,
       tiling: Tiling?) {
    self.id = id
    self.appToggleModifiers = appToggleModifiers
    self.bundleIdentifiers = bundleIdentifiers
    self.defaultForDynamicWorkspace = defaultForDynamicWorkspace
    self.hideOtherApps = hideOtherApps
    self.tiling = tiling
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.bundleIdentifiers, forKey: .bundleIdentifiers)
    try container.encodeIfPresent(self.tiling, forKey: .tiling)
    try container.encode(self.hideOtherApps, forKey: .hideOtherApps)
    if !self.appToggleModifiers.isEmpty {
      try container.encode(self.appToggleModifiers, forKey: .appToggleModifiers)
    }
    if self.defaultForDynamicWorkspace {
      try container.encode(self.defaultForDynamicWorkspace, forKey: .defaultForDynamicWorkspace)
    }
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.bundleIdentifiers = try container.decode([String].self, forKey: .bundleIdentifiers)
    self.tiling = try container.decodeIfPresent(WorkspaceCommand.Tiling.self, forKey: .tiling)
    self.hideOtherApps = try container.decode(Bool.self, forKey: .hideOtherApps)
    self.appToggleModifiers = try container.decodeIfPresent([ModifierKey].self, forKey: .appToggleModifiers) ?? []
    self.defaultForDynamicWorkspace = try container.decodeIfPresent(Bool.self, forKey: .defaultForDynamicWorkspace) ?? false
  }

  @MainActor
  func commands(_ applications: [Application], dynamicApps: [Application] = []) async throws -> [Command] {
    guard !UserSettings.WindowManager.stageManagerEnabled else {
      return whenStageManagerIsActive(applications)
    }

    let bundleIdentifiers = dynamicApps.map { $0.bundleIdentifier } + bundleIdentifiers

    guard !bundleIdentifiers.isEmpty else {
      return handleEmptyWorkspace()
    }

    let aerospaceIsRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "bobko.aerospace").isEmpty

    var commands = [Command]()

    let slowBundles = Set(["com.tinyspeck.slackmacgap"])
    let bundleIdentifiersCount = bundleIdentifiers.count
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let windows = indexWindowsInStage(getWindows([.optionOnScreenOnly, .excludeDesktopElements]))

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
    let windowPids = windows
      .map { $0.ownerPid.rawValue }

    let runningTargetAppsSet = Set(runningTargetApps)
    let windowPidsSet = Set(windowPids)
    let perfectBundleMatch = runningTargetAppsSet == windowPidsSet
                          && !runningApplications.isEmpty
                          && !windowPids.isEmpty

    let hideAllAppsCommand = Command.systemCommand(SystemCommand(
      kind: .hideAllApps,
      meta: Command.MetaData(delay: tiling != nil ? 40 : nil, name: "Hide All Apps")))

    for (offset, bundleIdentifier) in bundleIdentifiers.enumerated() {
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        continue
      }

      let runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
      let appIsRunning = runningApplication != nil
      let isFrontmost = frontmostApplication?.bundleIdentifier == bundleIdentifier
      let isLastItem = bundleIdentifiersCount - 1 == offset
      let action: ApplicationCommand.Action
      let name: String

      if let runningApplication, !windows.map(\.ownerPid.rawValue).contains(Int(runningApplication.processIdentifier)) {
        action = runningApplication.action
      } else if let runningApplication {
        if offset < runningApplications.count - 1,
           runningApplication.processIdentifier == windows[offset].ownerPid.rawValue {
          action = .unhide
        } else {
          if isLastItem && runningApplication.isActive == true {
            action = .open
          } else if runningApplication.isHidden == true {
            action = .unhide
          } else if runningApplication.isFinishedLaunching == true && !isLastItem {
            action = .unhide
          } else {
            action = runningApplication.action
          }
        }
      } else {
        action = tiling == nil ? .open : .unhide
      }

      name = action.displayName(for: application)

      if isLastItem {
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))

        let activationDelay: Double?

        if slowBundles.contains(application.bundleIdentifier) || application.metadata.isElectron {
          activationDelay = 225
        } else if perfectBundleMatch {
          activationDelay = 15
        } else {
          activationDelay = 40
        }

        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: activationDelay, name: "Activate \(application.displayName)"),
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
            meta: Command.MetaData(delay: 250, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch]
          )))
      } else {
        commands.append(
          .application(ApplicationCommand(
            action: action,
            application: application,
            meta: Command.MetaData(delay: 10, name: name), modifiers: [.waitForAppToLaunch]
          )))
      }
    }

    if hideOtherApps && !aerospaceIsRunning {
      if !perfectBundleMatch {
        commands.insert(hideAllAppsCommand, at: max(commands.count - 1, 0))
      }
    }

    let windowTiling: WindowTiling? = switch tiling {
    case .arrangeLeftRight:       .arrangeLeftRight
    case .arrangeRightLeft:       .arrangeRightLeft
    case .arrangeTopBottom:       .arrangeTopBottom
    case .arrangeBottomTop:       .arrangeBottomTop
    case .arrangeLeftQuarters:    .arrangeLeftQuarters
    case .arrangeRightQuarters:   .arrangeRightQuarters
    case .arrangeTopQuarters:     .arrangeTopQuarters
    case .arrangeBottomQuarters:  .arrangeBottomQuarters
    case .arrangeDynamicQuarters: .arrangeDynamicQuarters
    case .arrangeQuarters:        .arrangeQuarters
    case .fill:                   .fill
    case .center:                 .center
    case nil:                     nil
    }

    if let windowTiling, !aerospaceIsRunning {
      commands.append(.windowTiling(.init(kind: windowTiling, meta: Command.MetaData(name: "Window Tiling"))))
    }

    return commands
  }

  func copy() -> WorkspaceCommand {
    WorkspaceCommand(
      id: UUID().uuidString,
      appToggleModifiers: appToggleModifiers,
      bundleIdentifiers: bundleIdentifiers,
      defaultForDynamicWorkspace: defaultForDynamicWorkspace,
      hideOtherApps: hideOtherApps,
      tiling: tiling
    )
  }

  // MARK: Private methods

  private func whenStageManagerIsActive(_ applications: [Application]) -> [Command] {
    var commands: [Command] = []
    let runningApplications = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
    for (offset, bundleIdentifier) in bundleIdentifiers.enumerated() {
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        continue
      }

      let modifiers: [ApplicationCommand.Modifier]
      if offset == bundleIdentifiers.count - 1 {


        modifiers = [.waitForAppToLaunch]
      } else {
        if runningApplications.contains(application.bundleIdentifier) {
          continue
        }
        modifiers = [.background]
      }

      let applicationCommand = ApplicationCommand(action: .open, application: application, meta: Command.MetaData(delay: nil), modifiers: modifiers)

      commands.append(.application(applicationCommand))
    }


    return commands
  }

  private func handleEmptyWorkspace() -> [Command] {
    [
      Command.systemCommand(SystemCommand(
        kind: .hideAllApps,
        meta: Command.MetaData(delay: nil, name: "Clean Workspace")))
    ]
  }

  private func getWindows(_ options: CGWindowListOption) -> [WindowModel] {
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
        $0.rect.size.width > minimumSize.width &&
        $0.rect.size.height > minimumSize.height &&
        $0.alpha == 1 &&
        !excluded.contains($0.ownerName)
      }

    return windows
  }
}

private extension NSRunningApplication {
  var action: ApplicationCommand.Action {
    return if isHidden {
      .unhide
    } else {
      .open
    }
  }
}

private extension ApplicationCommand.Action {
  func displayName(for application: Application) -> String {
    switch self {
    case .open:   "Open \(application.displayName)"
    case .close:  "Close \(application.displayName)"
    case .hide:   "Hide \(application.displayName)"
    case .unhide: "Unhide \(application.displayName)"
    case .peek:   "Peek \(application.displayName)"
    }
  }
}
