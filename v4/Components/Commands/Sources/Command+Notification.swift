public extension Command {
  enum Notification: String, Identifiable, Codable, CaseIterable, Sendable {
    public var id: String { rawValue }
    case bezel
    case commandPanel
    case capsule
    var displayValue: String {
      switch self {
      case .bezel: "Bezel"
      case .commandPanel: "Command Panel"
      case .capsule: "Capsule UI"
      }
    }

    static var regularCases: [Notification] { [.bezel, .capsule] }
  }
}
