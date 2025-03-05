extension ApplicationCommand {
  enum Action: String, Codable, Hashable, Equatable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .open:  "Open"
      case .close: "Close"
      case .hide:  "Hide"
      case .unhide: "Unhide"
      case .peek: "Peek"
      }
    }
    case open, close, hide, unhide, peek
  }
}
