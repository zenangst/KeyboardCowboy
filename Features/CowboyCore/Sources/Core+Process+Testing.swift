#if DEBUG
import Foundation

extension Core.Process {
  public typealias ThrowingFunction = (@Sendable () throws -> Void)
  public typealias Function = (@Sendable () -> Void)

  final class Storage {
    var arguments: [String]?
    var currentDirectoryURL: URL?
    var environment: [String: String]?
    var executableURL: URL?
  }

  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var run: ThrowingFunction?
    var waitUntilExit: Function?
  }
}
#endif
