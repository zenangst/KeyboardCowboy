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
    var terminationStatus: Int32
    var terminationReason: Foundation.Process.TerminationReason
    var readStandardOutput: (@Sendable () throws -> Data?)?
    var readStandardError: (@Sendable () throws -> Data?)?

    public init(
      run: ThrowingFunction? = nil,
      waitUntilExit: Function? = nil,
      terminationStatus: Int32 = 0,
      terminationReason: Foundation.Process.TerminationReason = .exit,
      readStandardOutput: (@Sendable () throws -> Data?)? = nil,
      readStandardError: (@Sendable () throws -> Data?)? = nil
    ) {
      self.run = run
      self.waitUntilExit = waitUntilExit
      self.terminationStatus = terminationStatus
      self.terminationReason = terminationReason
      self.readStandardOutput = readStandardOutput
      self.readStandardError = readStandardError
    }
  }
}
#endif
