import Bonzai
import Cocoa
import Foundation

@MainActor
enum DesignTime {
  static let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"] ?? "SOURCE_ROOT"

  static var configurationsPublisher = ConfigurationsPublisher {
    [
      ConfigurationViewModel(
        id: UUID().uuidString,
        name: UUID().uuidString,
        selected: false,
        userModes: []
      ),
      ConfigurationViewModel(
        id: UUID().uuidString,
        name: UUID().uuidString,
        selected: false,
        userModes: []
      ),
    ]
  }

  static var configurationPublisher = ConfigurationPublisher(.init(id: UUID().uuidString, name: UUID().uuidString, selected: false, userModes: [
    .init(id: UUID().uuidString, name: "Vim mode", isEnabled: false)
  ]))

  static var groupsPublisher = GroupsPublisher {
    [
      GroupViewModel(id: UUID().uuidString, name: "Automation", icon: nil, color: "#EB5545", symbol: "autostartstop", userModes: [], count: 24),
      GroupViewModel(id: UUID().uuidString, name: "Applications", icon: nil, color: "#F2A23C", symbol: "app.dashed", userModes: [], count: 10),
      GroupViewModel(id: UUID().uuidString, name: "AppleScripts", icon: nil, color: "#F9D64A", symbol: "applescript", userModes: [], count: 5),
      GroupViewModel(id: UUID().uuidString, name: "Files & Folders", icon: nil, color: "#6BD35F", symbol: "folder", userModes: [], count: 2),
      GroupViewModel(id: UUID().uuidString, name: "Rebinding", icon: nil, color: "#3984F7", symbol: "app.connected.to.app.below.fill", userModes: [], count: 0),
      GroupViewModel(id: UUID().uuidString, name: "ShellScripts", icon: nil, color: "#B263EA", symbol: "terminal", userModes: [], count: 1),
      GroupViewModel(id: UUID().uuidString, name: "System", icon: nil, color: "#98989D", symbol: "laptopcomputer", userModes: [], count: 50),
      GroupViewModel(id: UUID().uuidString, name: "Websites", icon: nil, color: "#A78F6D", symbol: "safari", userModes: [], count: 14),
    ]
  }

  static let groupPublisher = GroupPublisher(GroupViewModel(id: UUID().uuidString, name: "Applications", icon: nil, color: "#F2A23C", symbol: "app.dashed", userModes: [], count: 10))
  static let infoPublisher: InfoPublisher = .init(.init(id: "empty", name: "", isEnabled: false))
  static let triggerPublisher: TriggerPublisher = .init(.keyboardShortcuts(.init(passthrough: false, holdDuration: nil, shortcuts: [
    .init(key: "a", modifiers: [.command])
  ])))
  static let commandsPublisher: CommandsPublisher = .init(.init(id: "empty", commands: [
    Self.applicationCommand.model,
    Self.menuBarCommand.model,
    Self.typeCommand.model
  ], execution: .concurrent))

  static var contentPublisher = ContentPublisher {
    [
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Application Trigger", images: [], overlayImages: [], badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open News", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/News.app", path: "/System/Applications/News.app")))
      ], overlayImages: [], trigger: .keyboard("ƒSpace"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Podcast", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Podcasts.app", path: "/System/Applications/Podcasts.app")))
      ], overlayImages: [], trigger: .keyboard("ƒU"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Music", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Music.app", path: "/System/Applications/Music.app")))
      ], overlayImages: [], trigger: .keyboard("ƒY"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Home", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Home.app", path: "/System/Applications/Home.app")))
      ], overlayImages: [], trigger: .keyboard("ƒH"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Twitterific", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/Applications/Twitterrific.app", path: "/Applications/Twitterrific.app")))
      ], overlayImages: [], trigger: .keyboard("ƒT"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open System Settings", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/System Settings.app", path: "/System/Applications/System Settings.app")))
      ], overlayImages: [], trigger: .keyboard("ƒ."), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Contacts", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Contacts.app", path: "/System/Applications/Contacts.app")))
      ], overlayImages: [], trigger: .keyboard("ƒA"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Terminal", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Utilities/Terminal.app", path: "/System/Applications/Utilities/Terminal.app")))
      ], overlayImages: [], trigger: .keyboard("ƒ§"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Discord", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/Applications/Discord.app", path: "/Applications/Discord.app")))
      ], overlayImages: [], trigger: .keyboard("ƒD"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Preview", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Preview.app", path: "/System/Applications/Preview.app")))
      ], overlayImages: [], trigger: .keyboard("ƒP"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Teams", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/Applications/Microsoft Teams.app", path: "/Applications/Microsoft Teams.app")))
      ], overlayImages: [], trigger: .keyboard("ƒG"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Slack", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/Applications/Slack.app", path: "/Applications/Slack.app")))
      ], overlayImages: [], trigger: .keyboard("ƒV"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Find My", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/FindMy.app", path: "/System/Applications/FindMy.app")))
      ], overlayImages: [], trigger: .keyboard("ƒB"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Messages", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Messages.app", path: "/System/Applications/Messages.app")))
      ], overlayImages: [], trigger: .keyboard("ƒD"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Mail", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Mail.app", path: "/System/Applications/Mail.app")))
      ], overlayImages: [], trigger: .keyboard("ƒM"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Calendar", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Calendar.app", path: "/System/Applications/Calendar.app")))
      ], overlayImages: [], trigger: .keyboard("ƒC"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Reminders", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Reminders.app", path: "/System/Applications/Reminders.app")))
      ], overlayImages: [], trigger: .keyboard("ƒR"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Notes", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Notes.app", path: "/System/Applications/Notes.app")))
      ], overlayImages: [], trigger: .keyboard("ƒN"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Finder", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Library/CoreServices/Finder.app", path: "/System/Library/CoreServices/Finder.app")))
      ], overlayImages: [], trigger: .keyboard("ƒF"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Photos", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Photos.app", path: "/System/Applications/Photos.app")))
      ], overlayImages: [], trigger: .keyboard("ƒI"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Stocks", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Stocks.app", path: "/System/Applications/Stocks.app")))
      ], overlayImages: [], trigger: .keyboard("ƒS"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Keyboard Cowboy", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/Applications/Keyboard Cowboy.app", path: "/Applications/Keyboard Cowboy.app")))
      ], overlayImages: [], trigger: .keyboard("⌥ƒ0"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Numbers", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Numbers.app", path: "/System/Applications/Numbers.app")))
      ], overlayImages: [], trigger: .keyboard("⌥ƒN"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Pages", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Pages.app", path: "/System/Applications/Pages.app")))
      ], overlayImages: [], trigger: .keyboard("⌥ƒP"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Keynote", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Keynote.app", path: "/System/Applications/Keynote.app")))
      ], overlayImages: [], trigger: .keyboard("⌥ƒK"), badge: 0, badgeOpacity: 0, isEnabled: true),
      ContentViewModel(id: UUID().uuidString, groupId: UUID().uuidString, name: "Open Quick Run", images: [
        ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .icon(.init(bundleIdentifier: "/System/Applications/Stocks.app", path: "/System/Applications/Stocks.app")))
      ], overlayImages: [], trigger: .keyboard("ƒK"), badge: 0, badgeOpacity: 0, isEnabled: true),
    ]
  }

  @MainActor
  static var detailStatePublisher = DetailStatePublisher { .single }

  static func metadata(name: String, notification: Command.Notification? = nil, icon: Icon?) -> CommandViewModel.MetaData {
    CommandViewModel.MetaData(
      id: UUID().uuidString,
      name: name,
      namePlaceholder: name,
      isEnabled: true,
      notification: notification,
      icon: icon,
      variableName: "")
  }

  static var applicationCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.ApplicationModel) {
    let kind = CommandViewModel.Kind.ApplicationModel(id: UUID().uuidString, action: "Open",
                                                      inBackground: false, hideWhenRunning: false,
                                                      ifNotRunning: false)
    return (.init(meta: metadata(name: "Xcode", icon: .init(bundleIdentifier: "com.apple.dt.Xcode",
                                                           path: "/Applications/Xcode.app")),
                  kind: .application(kind)), kind)
  }

  static var builtInCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.BuiltInModel) {
    let kind = CommandViewModel.Kind.BuiltInModel(id: UUID().uuidString, name: "Toggle", kind: .userMode(.init(id: UUID().uuidString, name: "", isEnabled: true), .toggle))
    return (.init(meta: metadata(name: "Dock", icon: .init(bundleIdentifier: "/System/Library/CoreServices/Dock.app",
                                                           path: "/System/Library/CoreServices/Dock.app")),
                  kind: .builtIn(kind)), kind)
  }

  static var menuBarCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.MenuBarModel) {
    let kind = CommandViewModel.Kind.MenuBarModel(id: UUID().uuidString, tokens: [
      .menuItem(name: "View"),
      .menuItem(name: "Navigators"),
      .menuItems(name: "Show Navigator", fallbackName: "Hide Navigator")
    ])
    return (.init(meta: metadata(name: "", icon: nil), kind: .menuBar(kind)), kind)
  }

  static var openCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.OpenModel) {
    let homeDirectory = ("~/" as NSString).expandingTildeInPath
    let kind = CommandViewModel.Kind.OpenModel(id: UUID().uuidString, path: homeDirectory, applications: [])

    return (.init(meta: metadata(
      name: "Home Folder",
      icon: .init(bundleIdentifier: homeDirectory, path: homeDirectory)),
                  kind: .open(kind)), kind)
  }

  static var mouseCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.MouseModel) {
    let kind = CommandViewModel.Kind.MouseModel(
      id: UUID().uuidString,
      kind: .click(.focused(.center))
    )
    let path = "/System/Library/Frameworks/IOBluetoothUI.framework/Versions/A/Resources/MightyMouse.icns"
    return (
      .init(
        meta: metadata(
          name: "Left Click",
          icon: .init(bundleIdentifier: path, path: path)),
        kind: .mouse(kind)
      ),
      kind
    )
  }

  static var scriptCommandWithPath: (model: CommandViewModel, kind: CommandViewModel.Kind.ScriptModel) {
    let scriptFile = Self.sourceRoot.appending("/Fixtures/AppleScript.scpt")
    let kind = CommandViewModel.Kind.ScriptModel(id: UUID().uuidString, source: .path(scriptFile), scriptExtension: .appleScript, variableName: "", execution: .concurrent)
    return (.init(meta: metadata(name: "Run AppleScript.scpt",
                                 icon: .init(bundleIdentifier: scriptFile, path: scriptFile)),
                  kind: .script(kind)), kind)
  }

  static var scriptCommandInline: (model: CommandViewModel, kind: CommandViewModel.Kind.ScriptModel) {
    let kind = CommandViewModel.Kind.ScriptModel(id: UUID().uuidString, source: .inline("pmset -g batt | grep -o '[0-9]\\{1,3\\}%'"), scriptExtension: .shellScript, variableName: "", execution: .serial)
    let scriptFile = Self.sourceRoot.appending("/Fixtures/AppleScript.scpt")

    return (.init(meta: metadata(name: "Show Battery Percentage",
                                 notification: .bezel,
                                 icon: .init(bundleIdentifier: scriptFile,
                                             path: scriptFile)),
                  kind: .script(kind)), kind)
  }

  static var rebindingCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.KeyboardModel) {
    let kind = CommandViewModel.Kind.KeyboardModel(id: UUID().uuidString, keys: [
      .init(id: UUID().uuidString, key: "F", lhs: false, modifiers: [.function, .command])
    ])
    return (.init(meta: metadata(name: "Rebind esc to enter", icon: nil),
           kind: .keyboard(kind)), kind)
  }

  static var shortcutCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.ShortcutModel) {
    let kind = CommandViewModel.Kind.ShortcutModel(id: UUID().uuidString, shortcutIdentifier: "Run shortcut")
    return (.init(meta: metadata(name: "Run shortcut", icon: nil),
                 kind: .shortcut(kind)), kind)
  }

  static var systemCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.SystemModel) {
    let kind = CommandViewModel.Kind.SystemModel(id: UUID().uuidString, kind: .moveFocusToNextWindow)
    return (.init(meta: metadata(name: "Run shortcut", icon: nil),
                 kind: .systemCommand(kind)), kind)
  }

  static var typeCommand: (model: CommandViewModel, kind: CommandViewModel.Kind.TypeModel) {
    let kind = CommandViewModel.Kind.TypeModel(id: UUID().uuidString, 
                                               mode: .instant,
                                               input: "typing ...")
    return (.init(meta: metadata(name: "Typing...", icon: nil), kind: .text(.init(kind: .type(.init(id: UUID().uuidString, mode: .instant, input: ""))))), kind)
  }

  static func windowCommand(_ kind: WindowCommand.Kind) -> (model: CommandViewModel, kind: WindowCommand.Kind) {
    let model = CommandViewModel.Kind.WindowManagementModel(id: UUID().uuidString, kind: kind, animationDuration: 0)
    return (.init(meta: metadata(name: "Window Management", icon: nil), kind: .windowManagement(model)), kind)
  }

  static var emptyDetail: DetailViewModel {
    DetailViewModel(
      info: .init(id: UUID().uuidString, name: UUID().uuidString, isEnabled: false),
      commandsInfo: .init(id: UUID().uuidString, commands: [], execution: .concurrent)
    )
  }

  static var detail: DetailViewModel {
    DetailViewModel(
      info: .init(
        id: UUID().uuidString,
        name: "Open News",
        isEnabled: true
      ),
      commandsInfo: .init(
        id: UUID().uuidString,
        commands: [
          Self.menuBarCommand.model,
          Self.applicationCommand.model,
          Self.openCommand.model,
          Self.scriptCommandWithPath.model,
          Self.scriptCommandInline.model,
          Self.rebindingCommand.model
        ],
        execution: .serial
      ),
      trigger: .keyboardShortcuts(
        .init(
          passthrough: false,
          shortcuts: [.init(
            key: "f",
            lhs: true,
            modifiers: [.function]
          )]
        )
      )
      )
  }
}
