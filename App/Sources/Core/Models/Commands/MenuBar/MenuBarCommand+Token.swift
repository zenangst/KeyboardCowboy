extension MenuBarCommand {
  enum Token: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: String {
      switch self {
      case let .menuItem(value):
        value
      case let .menuItems(lhs, rhs):
        lhs + rhs
      }
    }

    case menuItem(name: String)
    case menuItems(name: String, fallbackName: String)
  }
}
