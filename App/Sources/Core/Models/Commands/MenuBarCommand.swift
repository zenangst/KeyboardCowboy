import Apps
import Foundation

struct MenuBarCommand: MetaDataProviding {
  enum Token: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: String {
      switch self {
      case .menuItem(let value):
        return value
      case .menuItems(let lhs, let rhs):
        return lhs + rhs
      }
    }

    case menuItem(name: String)
    case menuItems(name: String, fallbackName: String)
  }

  let tokens: [Token]
  var application: Application?
  var meta: Command.MetaData

  init(id: String = UUID().uuidString, 
       name: String = "",
       application: Application?,
       tokens: [Token],
       isEnabled: Bool = true,
       notification: Bool = false) {
    self.application = application
    self.tokens = tokens
    self.meta = Command.MetaData(id: id, name: name,
                                 isEnabled: isEnabled,
                                 notification: notification)
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    do {
      self.meta = try container.decode(Command.MetaData.self, forKey: .meta)
    } catch {
      self.meta = try MetaDataMigrator.migrate(decoder)
    }

    self.tokens = try container.decode([Token].self, forKey: .tokens)
    self.application = try container.decodeIfPresent(Application.self, forKey: .application)
  }

  func copy() -> MenuBarCommand {
    MenuBarCommand(id: UUID().uuidString,
                   name: meta.name,
                   application: application,
                   tokens: tokens,
                   notification: meta.notification)
  }
}
