import CowboyCore
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

  /// The process configuration as it stood immediately before a mock launch.
  public struct LaunchConfiguration: Sendable, Equatable {
    public let arguments: [String]?
    public let currentDirectoryURL: URL?
    public let environment: [String: String]?
    public let executableURL: URL?
  }

  public struct Mock: Sendable {
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
      readStandardError: (@Sendable () throws -> Data?)? = nil
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
