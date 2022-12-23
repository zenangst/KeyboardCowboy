import Foundation
import Cocoa

enum DesignTime {
  static let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"] ?? "SOURCE_ROOT"

  static var configurationPublisher = ConfigurationPublisher {
    [
      ConfigurationViewModel(id: UUID().uuidString, name: UUID().uuidString),
      ConfigurationViewModel(id: UUID().uuidString, name: UUID().uuidString),
    ]
  }

  static var groupsPublisher = GroupsPublisher {
    [
      GroupViewModel(id: UUID().uuidString, name: "fn-key", image: nil, color: "", symbol: "", count: 24),
      GroupViewModel(id: UUID().uuidString, name: "Finder", image: nil, color: "", symbol: "", count: 10),
      GroupViewModel(id: UUID().uuidString, name: "Safari", image: nil, color: "", symbol: "", count: 5),
      GroupViewModel(id: UUID().uuidString, name: "Xcode", image: nil, color: "", symbol: "", count: 2),
      GroupViewModel(id: UUID().uuidString, name: "Apple News", image: nil, color: "", symbol: "", count: 0),
      GroupViewModel(id: UUID().uuidString, name: "Messages", image: nil, color: "", symbol: "", count: 1),
      GroupViewModel(id: UUID().uuidString, name: "Global", image: nil, color: "", symbol: "", count: 50),
      GroupViewModel(id: UUID().uuidString, name: "Web pages", image: nil, color: "", symbol: "", count: 14),
      GroupViewModel(id: UUID().uuidString, name: "Development", image: nil, color: "", symbol: "", count: 6),
      GroupViewModel(id: UUID().uuidString, name: "Folders", image: nil, color: "", symbol: "", count: 8),
    ]
  }
  static var contentPublisher = ContentPublisher {
   [
    ContentViewModel(id: UUID().uuidString, name: "Open News", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/News.app")))
    ], binding: "ƒSpace", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Podcast", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Podcasts.app")))
    ], binding: "ƒU", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Music", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Music.app")))
    ], binding: "ƒY", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Home", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Home.app")))
    ], binding: "ƒH", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Twitterific", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/Applications/Twitterrific.app")))
    ], binding: "ƒT", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open System Settings", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/System Settings.app")))
    ], binding: "ƒ.", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Contacts", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Contacts.app")))
    ], binding: "ƒA", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Terminal", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app")))
    ], binding: "ƒ§", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Discord", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/Applications/Discord.app")))
    ], binding: "ƒD", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Preview", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Preview.app")))
    ], binding: "ƒP", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Teams", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/Applications/Microsoft Teams.app")))
    ], binding: "ƒG", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Slack", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/Applications/Slack.app")))
    ], binding: "ƒV", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Find My", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/FindMy.app")))
    ], binding: "ƒB", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Messages", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Messages.app")))
    ], binding: "ƒD", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Mail", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Mail.app")))
    ], binding: "ƒM", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Calendar", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Calendar.app")))
    ], binding: "ƒC", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Reminders", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Reminders.app")))
    ], binding: "ƒR", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Notes", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Notes.app")))
    ], binding: "ƒN", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Finder", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")))
    ], binding: "ƒF", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Photos", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Photos.app")))
    ], binding: "ƒI", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Stocks", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Stocks.app")))
    ], binding: "ƒS", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Keyboard Cowboy", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/Applications/Keyboard Cowboy.app")))
    ], binding: "⌥ƒ0", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Numbers", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Numbers.app")))
    ], binding: "⌥ƒN", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Pages", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Pages.app")))
    ], binding: "⌥ƒP", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Keynote", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Keynote.app")))
    ], binding: "⌥ƒK", badge: 0, badgeOpacity: 0),
    ContentViewModel(id: UUID().uuidString, name: "Open Quick Run", images: [
      ContentViewModel.ImageModel(id: UUID().uuidString, offset: 0, kind: .nsImage(NSWorkspace.shared.icon(forFile: "/System/Applications/Stocks.app")))
    ], binding: "ƒK", badge: 0, badgeOpacity: 0),
   ]
  }
  static var detailPublisher = DetailPublisher {
    .single(detail)
  }

  static var applicationCommand: DetailViewModel.CommandViewModel {
    .init(id: UUID().uuidString,
          name: "News",
          kind: .application(action: "Open", inBackground: true, hideWhenRunning: false, ifNotRunning: false),
          image: NSWorkspace.shared.icon(forFile: "/System/Applications/News.app"),
          isEnabled: true)
  }

  static var openCommand: DetailViewModel.CommandViewModel {
    let homeDirectory = ("~/" as NSString).expandingTildeInPath
    return .init(id: UUID().uuidString,
                 name: "Home Folder",
                 kind: .open(appName: nil),
                 image: NSWorkspace.shared.icon(forFile: homeDirectory),
                 isEnabled: true)
  }

  static var scriptCommandWithPath: DetailViewModel.CommandViewModel {
    let scriptFile = Self.sourceRoot.appending("/Fixtures/AppleScript.scpt")
    return .init(id: UUID().uuidString,
                 name: scriptFile,
                 kind: .script(.path(id: UUID().uuidString, fileExtension: "scpt")),
                 image: NSWorkspace.shared.icon(forFile: scriptFile),
                 isEnabled: true)
  }

  static var scriptCommandInline: DetailViewModel.CommandViewModel {
    let scriptFile = Self.sourceRoot.appending("/Fixtures/AppleScript.scpt")
    return .init(id: UUID().uuidString,
          name: "Left align the Dock",
          kind: .script(.inline(id: UUID().uuidString, type: "script")),
          image: NSWorkspace.shared.icon(forFile: scriptFile),
          isEnabled: true)
  }

  static var rebindingCommand: DetailViewModel.CommandViewModel {
    .init(id: UUID().uuidString,
          name: "Rebind esc to enter",
          kind: .keyboard(key: "F", modifiers: [.function, .command]),
          image: nil,
          isEnabled: true)
  }

  static var shortcutCommand: DetailViewModel.CommandViewModel {
    .init(id: UUID().uuidString, name: "Run shortcut", kind: .shortcut, image: nil, isEnabled: true)
  }

  static var typeCommand: DetailViewModel.CommandViewModel {
    .init(id: UUID().uuidString, name: "Type command", kind: .type, image: nil, isEnabled: true)
  }


  static var detail: DetailViewModel {
    DetailViewModel(
      id: UUID().uuidString,
      name: "Open News",
      isEnabled: true,
      trigger: .keyboardShortcuts([.init(id: UUID().uuidString, displayValue: "f", modifier: .shift)]),
      commands: [
        Self.applicationCommand,
        Self.openCommand,
        Self.scriptCommandWithPath,
        Self.scriptCommandInline,
        Self.rebindingCommand
      ])
  }
}
