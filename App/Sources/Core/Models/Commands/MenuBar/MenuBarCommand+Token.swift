extension MenuBarCommand {
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
}
