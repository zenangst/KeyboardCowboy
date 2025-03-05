extension WindowManagementCommand {
  enum Direction: String, Identifiable, Codable, CaseIterable {
    var id: String { rawValue }

    case topLeading
    case top
    case topTrailing
    case leading
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing

    func imageSystemName(increment: Bool) -> String {
      switch self {
      case .leading: increment ? "arrow.left" : "arrow.right"
      case .topLeading: increment ? "arrow.up.left" : "arrow.down.right"
      case .top: increment ? "arrow.up" : "arrow.down"
      case .topTrailing: increment ? "arrow.up.right" : "arrow.down.left"
      case .trailing: increment ? "arrow.right" : "arrow.left"
      case .bottomTrailing: increment ? "arrow.down.right" : "arrow.up.left"
      case .bottom: increment ? "arrow.down" : "arrow.up"
      case .bottomLeading: increment ? "arrow.down.left" : "arrow.up.right"
      }
    }

    func displayValue(increment: Bool) -> String {
      switch self {
      case .leading: increment ? "←" : "→"
      case .topLeading: increment ? "↖" : "↘"
      case .top: increment ? "↑" : "↓"
      case .topTrailing: increment ? "↗" : "↙"
      case .trailing: increment ? "→" : "←"
      case .bottomTrailing: increment ? "↘" : "↖"
      case .bottom: increment ? "↓" : "↑"
      case .bottomLeading: increment ? "↙" : "↗"
      }
    }
  }
}
