import Foundation

struct SystemCommand: MetaDataProviding {
  enum Kind: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    var displayValue: String {
      switch self {
      case .applicationWindows:
        return "Application windows"
      case .missionControl:
        return "Mission Control"
      case .showDesktop:
        return "Show Desktop"
      case .moveFocusToNextWindowGlobal:
        return "Move focus to next window (all windows)"
      case .moveFocusToPreviousWindowGlobal:
        return "Move focus to previous window (all windows)"
      case .moveFocusToNextWindow:
        return "Move focus to next window"
      case .moveFocusToPreviousWindow:
        return "Move focus to previous window"
      case .moveFocusToNextWindowFront:
        return "Move focus to next window of active application"
      case .moveFocusToPreviousWindowFront:
        return "Move focus to previous window of active application"
      }
    }

    case applicationWindows
    case moveFocusToNextWindowFront
    case moveFocusToPreviousWindowFront
    case moveFocusToNextWindow
    case moveFocusToPreviousWindow
    case moveFocusToNextWindowGlobal
    case moveFocusToPreviousWindowGlobal
    case missionControl
    case showDesktop
  }
  var kind: Kind
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, name: String, kind: Kind, notification: Bool) {
    self.kind = kind
    self.meta = Command.MetaData(id: id, name: name, isEnabled: true, notification: notification)
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
}
