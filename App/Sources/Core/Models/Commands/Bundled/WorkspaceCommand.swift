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

    var id: String { rawValue }
  }

  enum CodingKeys: CodingKey {
    case id
    case appToggleModifiers
    case bundleIdentifiers
    case applications
    case defaultForDynamicWorkspace
    case hideOtherApps
    case tiling
  }

  struct WorkspaceApplication: Codable, Hashable, Identifiable {
    enum Option: String, Codable {
      case onlyWhenRunning
    }

    var id: String { bundleIdentifier }

    let bundleIdentifier: String
    let options: [Option]

    init(bundleIdentifier: String, options: [Option] = []) {
      self.bundleIdentifier = bundleIdentifier
      self.options = options
    }

    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
      if !options.isEmpty {
        try container.encode(options, forKey: .options)
      }
    }

    enum CodingKeys: CodingKey {
      case bundleIdentifier
      case options
    }

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<WorkspaceCommand.WorkspaceApplication.CodingKeys> = try decoder.container(keyedBy: WorkspaceCommand.WorkspaceApplication.CodingKeys.self)
      bundleIdentifier = try container.decode(String.self, forKey: WorkspaceCommand.WorkspaceApplication.CodingKeys.bundleIdentifier)
      if let options = try? container.decodeIfPresent([WorkspaceCommand.WorkspaceApplication.Option].self, forKey: WorkspaceCommand.WorkspaceApplication.CodingKeys.options) {
        self.options = options
      } else {
        options = []
      }
    }
  }

  var id: String
  var applications: [WorkspaceApplication]
  var tiling: Tiling?
  var hideOtherApps: Bool
  var appToggleModifiers: [ModifierKey]

  var defaultForDynamicWorkspace: Bool
  var isDynamic: Bool { applications.isEmpty }

  init(id: String = UUID().uuidString,
       assignmentModifierS _: [ModifierKey] = [],
       appToggleModifiers: [ModifierKey] = [],
       applications: [WorkspaceApplication] = [],
       defaultForDynamicWorkspace: Bool,
       hideOtherApps: Bool,
       tiling: Tiling?) {
    self.id = id
    self.appToggleModifiers = appToggleModifiers
    self.applications = applications
    self.defaultForDynamicWorkspace = defaultForDynamicWorkspace
    self.hideOtherApps = hideOtherApps
    self.tiling = tiling
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)

    if !applications.isEmpty {
      try container.encode(applications, forKey: .applications)
    }

    try container.encodeIfPresent(tiling, forKey: .tiling)
    try container.encode(hideOtherApps, forKey: .hideOtherApps)
    if !appToggleModifiers.isEmpty {
      try container.encode(appToggleModifiers, forKey: .appToggleModifiers)
    }
    if defaultForDynamicWorkspace {
      try container.encode(defaultForDynamicWorkspace, forKey: .defaultForDynamicWorkspace)
    }
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)

    if let bundleIdentifiers = try? container.decodeIfPresent([String].self, forKey: .bundleIdentifiers) {
      applications = bundleIdentifiers.map { WorkspaceApplication(bundleIdentifier: $0, options: []) }
    } else {
      applications = try container.decodeIfPresent([WorkspaceApplication].self, forKey: .applications) ?? []
    }

    tiling = try container.decodeIfPresent(WorkspaceCommand.Tiling.self, forKey: .tiling)
    hideOtherApps = try container.decode(Bool.self, forKey: .hideOtherApps)
    appToggleModifiers = try container.decodeIfPresent([ModifierKey].self, forKey: .appToggleModifiers) ?? []
    defaultForDynamicWorkspace = try container.decodeIfPresent(Bool.self, forKey: .defaultForDynamicWorkspace) ?? false
  }

  @MainActor func commands(_ applications: [Application], snapshot _: inout UserSpace.Snapshot, dynamicApps: [Application] = []) throws -> [Command] {
    guard !UserSettings.WindowManager.stageManagerEnabled else {
      return whenStageManagerIsActive(applications, dynamicApps: dynamicApps)
    }

    let bundleIdentifiers = dynamicApps.map(\.bundleIdentifier) + self.applications.compactMap { app in
      if app.options.contains(.onlyWhenRunning) {
        if !NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier).isEmpty {
          app.bundleIdentifier
        } else {
          nil
        }
      } else {
        app.bundleIdentifier
      }
    }

    guard !bundleIdentifiers.isEmpty else {
      return handleEmptyWorkspace()
    }

    let aerospaceIsRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "bobko.aerospace").isEmpty

    var commands = [Command]()

    let bundleIdentifiersCount = bundleIdentifiers.count
    let frontmostApplication = NSWorkspace.shared.frontmostApplication
    let windows = indexWindowsInStage(getWindows([.excludeDesktopElements]))
    let runningApplications = windows
      .compactMap { NSRunningApplication(processIdentifier: Int32($0.ownerPid.rawValue)) }

    let runningTargetApps: [Int] = runningApplications
      .compactMap {
        guard let bundleIdentifier = $0.bundleIdentifier,
              bundleIdentifiers.contains(bundleIdentifier) else { return nil }

        return Int($0.processIdentifier)
      }

    let windowPids = windows.map(\.ownerPid.rawValue)
    let runningTargetAppsSet = Set(runningTargetApps)
    let windowPidsSet = Set(windowPids)
    let perfectBundleMatch = runningTargetAppsSet == windowPidsSet
      && !runningApplications.isEmpty
      && !windowPids.isEmpty

    let hideAllAppsCommand = Command.systemCommand(SystemCommand(
      kind: .hideAllApps,
      meta: Command.MetaData(delay: tiling != nil ? 40 : nil, name: "Hide All Apps"),
    ))

    for (offset, bundleIdentifier) in bundleIdentifiers.enumerated() {
      guard let application = applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
        continue
      }

      let runningApplication = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
      let appIsRunning = runningApplication != nil
      let isFrontmost = frontmostApplication?.bundleIdentifier == bundleIdentifier
      let isLastItem = bundleIdentifiersCount - 1 == offset
      var action: ApplicationCommand.Action
      let name: String

      if let runningApplication, !windows.map(\.ownerPid.rawValue).contains(Int(runningApplication.processIdentifier)) {
        action = runningApplication.action
      } else if let runningApplication {
        if bundleIdentifiers.count == 1 {
          action = .open
        } else if offset < runningApplications.count - 1,
                  runningApplication.processIdentifier == windows[offset].ownerPid.rawValue {
          action = .unhide
        } else {
          if isLastItem, runningApplication.isActive == true {
            action = .open
          } else if runningApplication.isHidden == true {
            action = .unhide
          } else if runningApplication.isFinishedLaunching == true, !isLastItem {
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
            meta: Command.MetaData(delay: nil, name: "Activate \(application.displayName)"),
            modifiers: [.waitForAppToLaunch],
          )))
      } else if isFrontmost {
        commands.append(
          .application(ApplicationCommand(
            action: .unhide,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Unhide frontmost application \(application.displayName)"),
            modifiers: [.waitForAppToLaunch],
          )))
      } else if !appIsRunning {
        commands.append(
          .application(ApplicationCommand(
            action: .open,
            application: application,
            meta: Command.MetaData(delay: nil, name: "Open \(application.displayName)"),
            modifiers: [.waitForAppToLaunch],
          )))
      } else {
        commands.append(
          .application(ApplicationCommand(
            action: action,
            application: application,
            meta: Command.MetaData(delay: nil, name: name), modifiers: [.waitForAppToLaunch, .background],
          )))
      }
    }

    let windowTiling: WindowTiling? = switch tiling {
    case .arrangeLeftRight: .arrangeLeftRight
    case .arrangeRightLeft: .arrangeRightLeft
    case .arrangeTopBottom: .arrangeTopBottom
    case .arrangeBottomTop: .arrangeBottomTop
    case .arrangeLeftQuarters: .arrangeLeftQuarters
    case .arrangeRightQuarters: .arrangeRightQuarters
    case .arrangeTopQuarters: .arrangeTopQuarters
    case .arrangeBottomQuarters: .arrangeBottomQuarters
    case .arrangeDynamicQuarters: .arrangeDynamicQuarters
    case .arrangeQuarters: .arrangeQuarters
    case .fill: .fill
    case .center: .center
    case nil: nil
    }

    if let windowTiling, !aerospaceIsRunning {
      commands.append(.windowTiling(.init(kind: windowTiling, meta: Command.MetaData(name: "Window Tiling"))))
    }

    if hideOtherApps, !aerospaceIsRunning, !UserSettings.WindowManager.stageManagerEnabled {
      commands.append(hideAllAppsCommand)
    }

    return commands
  }

  func copy() -> WorkspaceCommand {
    WorkspaceCommand(
      id: UUID().uuidString,
      appToggleModifiers: appToggleModifiers,
      applications: applications,
      defaultForDynamicWorkspace: defaultForDynamicWorkspace,
      hideOtherApps: hideOtherApps,
      tiling: tiling,
    )
  }

  // MARK: Private methods

  private func whenStageManagerIsActive(_ applications: [Application], dynamicApps: [Application]) -> [Command] {
    var commands: [Command] = []
    let runningApplications = NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)

    var bundleIdentifiers: [String] = self.applications.map(\.bundleIdentifier)
    for dynamicApp in dynamicApps {
      bundleIdentifiers.append(dynamicApp.bundleIdentifier)
    }

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
        meta: Command.MetaData(delay: nil, name: "Clean Workspace"),
      )),
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
    if isHidden {
      .unhide
    } else {
      .open
    }
  }
}

private extension ApplicationCommand.Action {
  func displayName(for application: Application) -> String {
    switch self {
    case .open: "Open \(application.displayName)"
    case .close: "Close \(application.displayName)"
    case .hide: "Hide \(application.displayName)"
    case .unhide: "Unhide \(application.displayName)"
    case .peek: "Peek \(application.displayName)"
    }
  }
}
