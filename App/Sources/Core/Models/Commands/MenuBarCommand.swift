import Foundation

struct MenuBarCommand: Equatable, Hashable, Codable {
  enum Token: Equatable, Hashable, Codable {
    case pick(String)
    case toggle(String, String)
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
