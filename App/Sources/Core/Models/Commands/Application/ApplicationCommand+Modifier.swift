extension ApplicationCommand {
  enum Modifier: String, Codable, Hashable, CaseIterable, Sendable {
    public var id: String { return self.rawValue }
    public var displayValue: String {
      switch self {
      case .background: "Open in background"
      case .hidden: "Hide when opening"
      case .onlyIfNotRunning: "Open if not running"
      case .addToStage: "Add to current stage"
      case .waitForAppToLaunch: "Wait for app to launch"
      }
    }
    case background
    case hidden
    case onlyIfNotRunning
    case addToStage
    case waitForAppToLaunch
  }
}
