import Foundation

public extension Core {
  enum ProcessInfo {
    private typealias Production = Foundation.ProcessInfo

    public static func environment(_ env: Environment) -> [String: String] {
      switch env {
      case .production: Production.processInfo.environment
      #if DEBUG
      case .testing: Testing.mock
      #endif
      }
    }
  }
}
