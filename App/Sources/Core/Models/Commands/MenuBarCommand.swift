import Foundation

struct MenuBarCommand: Equatable, Hashable, Codable {
  enum Token: Identifiable, Equatable, Hashable, Codable {
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

  var id: String
  let tokens: [Token]
  var name: String
  var isEnabled: Bool = true
  var notification: Bool

  init(id: String = UUID().uuidString, name: String = "",
       tokens: [Token],
       isEnabled: Bool = true,
       notification: Bool = false) {
    self.id = id
    self.name = name
    self.tokens = tokens
    self.isEnabled = isEnabled
    self.notification = notification
  }
}
