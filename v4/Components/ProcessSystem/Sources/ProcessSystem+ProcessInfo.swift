import Foundation
import RuntimeEnvironment

public extension ProcessSystem {
  enum ProcessInfo {
    private typealias Production = Foundation.ProcessInfo

    public static func environment(_ env: RuntimeEnvironment.Mode) -> [String: String] {
      switch env {
      case .production: Production.processInfo.environment
      #if DEBUG
      case .testing: Testing.mock
      #endif
      }
    }
  }
}
