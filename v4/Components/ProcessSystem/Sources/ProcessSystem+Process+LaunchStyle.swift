public extension ProcessSystem.Process {
  enum LaunchStyle: Equatable {
    case shell(String)
    case headless(String)

    public var source: String {
      switch self {
      case .shell(let string): string
      case .headless(let string): string
      }
    }
  }
}
