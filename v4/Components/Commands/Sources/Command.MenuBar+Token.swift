public extension Command.MenuBar {
  enum Token: Codable, Hashable, Sendable {
    case menuItem(name: String)
    case menuItems(name: String, fallbackName: String)
  }
}
