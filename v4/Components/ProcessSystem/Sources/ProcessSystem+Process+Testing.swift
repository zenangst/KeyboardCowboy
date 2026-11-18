#if DEBUG
import Foundation

public extension ProcessSystem.Process {
  typealias ThrowingFunction = (@Sendable () throws -> Void)
  typealias Function = (@Sendable () -> Void)

  internal final class Storage {
    var arguments: [String]?
    var currentDirectoryURL: URL?
    var environment: [String: String]?
    var executableURL: URL?
  }

  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  /// The process configuration as it stood immediately before a mock launch.
  struct LaunchConfiguration: Sendable, Equatable {
    public let arguments: [String]?
    public let currentDirectoryURL: URL?
    public let environment: [String: String]?
    public let executableURL: URL?
  }

  struct Mock: Sendable {
    var observeLaunch: (@Sendable (LaunchConfiguration) -> Void)?
    var run: ThrowingFunction?
    var waitUntilExit: Function?
    var terminationStatus: Int32
    var observeTerminationStatus: Function?
    var terminationReason: Foundation.Process.TerminationReason
    var readStandardOutput: (@Sendable () throws -> Data?)?
    var readStandardError: (@Sendable () throws -> Data?)?

    public init(
      observeLaunch: (@Sendable (LaunchConfiguration) -> Void)? = nil,
      run: ThrowingFunction? = nil,
      waitUntilExit: Function? = nil,
      terminationStatus: Int32 = 0,
      observeTerminationStatus: Function? = nil,
      terminationReason: Foundation.Process.TerminationReason = .exit,
      readStandardOutput: (@Sendable () throws -> Data?)? = nil,
      readStandardError: (@Sendable () throws -> Data?)? = nil,
    ) {
      self.observeLaunch = observeLaunch
      self.run = run
      self.waitUntilExit = waitUntilExit
      self.terminationStatus = terminationStatus
      self.observeTerminationStatus = observeTerminationStatus
      self.terminationReason = terminationReason
      self.readStandardOutput = readStandardOutput
      self.readStandardError = readStandardError
    }
  }
}
#endif
