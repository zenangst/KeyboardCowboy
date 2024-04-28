import Foundation

struct SystemCommand: MetaDataProviding {
  enum Kind: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    var displayValue: String {
      switch self {
      case .activateLastApplication:         "Activate Last Application"
      case .applicationWindows:              "Application Windows"
      case .minimizeAllOpenWindows:          "Minimize All Open Windows"
      case .missionControl:                  "Mission Control"
      case .showDesktop:                     "Show Desktop"
      case .moveFocusToNextWindowGlobal:     "Move Focus to Next Window (All Windows)"
      case .moveFocusToPreviousWindowGlobal: "Move Focus to Previous window (All Windows)"
      case .moveFocusToNextWindow:           "Move Focus to Next Window"
      case .moveFocusToPreviousWindow:       "Move Focus to Previous Window"
      case .moveFocusToNextWindowFront:      "Move Focus to Next Window of Active Application"
      case .moveFocusToPreviousWindowFront:  "Move Focus to Previous Window of Active Application"
      }
    }

    var symbol: String {
      switch self {
      case .activateLastApplication:         "arrow.counterclockwise.circle"
      case .applicationWindows:              "rectangle.on.rectangle"
      case .minimizeAllOpenWindows:          "arrow.down.right.and.arrow.up.left"
      case .missionControl:                  "square.grid.3x3"
      case .showDesktop:                     "desktopcomputer"
      case .moveFocusToNextWindowGlobal:     "arrow.right.circle"
      case .moveFocusToPreviousWindowGlobal: "arrow.left.circle"
      case .moveFocusToNextWindow:           "arrow.right.to.line.alt"
      case .moveFocusToPreviousWindow:       "arrow.left.to.line.alt"
      case .moveFocusToNextWindowFront:      "arrow.forward.circle"
      case .moveFocusToPreviousWindowFront:  "arrow.backward.circle"
      }
    }

    var iconPath: String {
      switch self {
      case .activateLastApplication:                                     "/System/Library/CoreServices/Family.app"
      case .applicationWindows:                                          "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindowFront:                                  "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToPreviousWindowFront:                              "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToNextWindow, .moveFocusToNextWindowGlobal:         "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .moveFocusToPreviousWindow, .moveFocusToPreviousWindowGlobal: "/System/Library/CoreServices/WidgetKit Simulator.app/Contents/Resources/AppIcon.icns"
      case .minimizeAllOpenWindows:                                      "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .missionControl:                                              "/System/Applications/Mission Control.app/Contents/Resources/AppIcon.icns"
      case .showDesktop:                                                 "/System/Library/CoreServices/Dock.app/Contents/Resources/Dock.icns"
      }
    }

    case activateLastApplication
    case applicationWindows
    case minimizeAllOpenWindows
    case missionControl
    case moveFocusToNextWindowFront
    case moveFocusToPreviousWindowFront
    case moveFocusToNextWindow
    case moveFocusToPreviousWindow
    case moveFocusToNextWindowGlobal
    case moveFocusToPreviousWindowGlobal
    case showDesktop
  }
  var kind: Kind
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, name: String, kind: Kind, 
       notification: Command.Notification? = nil) {
    self.kind = kind
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
  }

  init(kind: Kind, meta: Command.MetaData) {
    self.kind = kind
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.kind = try container.decode(Kind.self, forKey: .kind)
    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }
  }

  func copy() -> SystemCommand {
    SystemCommand(kind: kind, meta: meta.copy())
  }
}
