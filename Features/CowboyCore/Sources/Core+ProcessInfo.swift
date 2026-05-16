import Foundation

public extension Core {
  enum ProcessInfo {
    private typealias Production = Foundation.ProcessInfo

    public enum Testing {
      @TaskLocal public static var mock: [String: String] = [:]
    }

    public static func environment(_ env: Environment) -> [String: String] {
      switch env {
      case .production: Production.processInfo.environment
      case .testing: Testing.mock
      }
    }
  }
}
