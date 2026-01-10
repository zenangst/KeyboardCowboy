import Apps
import Foundation

struct MenuBarCommand: MetaDataProviding {
  let tokens: [Token]
  var application: Application?
  var meta: Command.MetaData

  init(id: String = UUID().uuidString,
       name: String = "",
       application: Application?,
       tokens: [Token],
       isEnabled: Bool = true,
       notification: Command.Notification? = nil) {
    self.application = application
    self.tokens = tokens
    meta = Command.MetaData(id: id, name: name,
                            isEnabled: isEnabled,
                            notification: notification)
  }

  init(application: Application?, tokens: [Token], meta: Command.MetaData) {
    self.application = application
    self.tokens = tokens
    self.meta = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    meta = try container.decode(Command.MetaData.self, forKey: .meta)
    tokens = try container.decode([Token].self, forKey: .tokens)
    application = try container.decodeIfPresent(Application.self, forKey: .application)
  }

  func copy() -> MenuBarCommand {
    MenuBarCommand(application: application, tokens: tokens, meta: meta.copy())
  }
}

extension MenuBarCommand.Token {
  static func top() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top")]
  }

  static func left() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left")]
  }

  static func right() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right")]
  }

  static func bottom() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom")]
  }

  static func topLeft() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top Left")]
  }

  static func topRight() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top Right")]
  }

  static func bottomLeft() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom Left")]
  }

  static func bottomRight() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom Right")]
  }

  static func center() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Center")]
  }

  static func fill() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Fill")]
  }

  static func zoom() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Fill")]
  }

  static func topBottom() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Bottom")]
  }

  static func bottomTop() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Bottom")]
  }

  static func leftRight() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Right")]
  }

  static func rightLeft() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Left")]
  }

  static func leftQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Left & Quarters")]
  }

  static func rightQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Right & Quarters")]
  }

  static func topQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Top & Quarters")]
  }

  static func bottomQuarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Bottom & Quarters")]
  }

  static func quarters() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Quarters")]
  }

  static func returnPreviousSize() -> [Self] {
    [.menuItem(name: "Window"), .menuItem(name: "Move & Resize"), .menuItem(name: "Return to Previous Size")]
  }
}
