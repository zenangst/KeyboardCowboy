import Foundation

public extension Core {
  final class Process {
    public typealias ThrowingFunction = (@Sendable () throws -> Void)
    public typealias Function = (@Sendable () -> Void)

    public enum LaunchStyle: Equatable {
      case shell(String)
      case headless(String)

      public var source: String {
        switch self {
        case .shell(let string): string
        case .headless(let string): string
        }
      }
    }

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

    enum Mode {
      case production(Foundation.Process)
      case testing(Storage)
    }

    let mode: Mode
    public let launchStyle: LaunchStyle

    public var arguments: [String]? {
      get {
        switch mode {
        case .production(let process): process.arguments
        case .testing(let storage): storage.arguments
        }
      }
      set {
        switch mode {
        case .production(let process): process.arguments = newValue
        case .testing(let storage): storage.arguments = newValue
        }
      }
    }

    public var currentDirectoryURL: URL? {
      get {
        switch mode {
        case .production(let process): process.currentDirectoryURL
        case .testing(let storage): storage.currentDirectoryURL
        }
      }
      set {
        switch mode {
        case .production(let process): process.currentDirectoryURL = newValue
        case .testing(let storage): storage.currentDirectoryURL = newValue
        }
      }
    }

    public var executableURL: URL? {
      get {
        switch mode {
        case .production(let process): process.executableURL
        case .testing(let storage): storage.executableURL
        }
      }
      set {
        switch mode {
        case .production(let process): process.executableURL = newValue
        case .testing(let storage): storage.executableURL = newValue
        }
      }
    }

    public var environment: [String: String]? {
      get {
        switch mode {
        case .production(let process): process.environment
        case .testing(let storage): storage.environment
        }
      }
      set {
        switch mode {
        case .production(let process): process.environment = newValue
        case .testing(let storage): storage.environment = newValue
        }
      }
    }

    public var standardError: Core.Pipe? {
      didSet {
        guard case .production(let process) = mode else {
          return
        }

        switch standardError?.mode {
        case .production(let pipe):
          process.standardError = pipe
        default:
          process.standardError = standardError
        }
      }
    }

    public var standardOutput: Core.Pipe? {
      didSet {
        guard case .production(let process) = mode else { return }

        switch standardOutput?.mode {
        case .production(let pipe):
          process.standardOutput = pipe
        default:
          process.standardOutput = standardOutput
        }
      }
    }

    public let source: String

    public init(_ env: Environment, launchStyle: LaunchStyle) {
      self.source = launchStyle.source
      self.launchStyle = launchStyle

      self.mode = switch env {
      case .production: .production(Foundation.Process())
      case .testing: .testing(Storage())
      }
    }

    public func run() throws {
      switch mode {
      case .production(let process):
        try process.run()
      case .testing:
        try Testing.mock.run?()
      }
    }

    public func waitUntilExit() {
      switch mode {
      case .production(let process):
        process.waitUntilExit()
      case .testing:
        Testing.mock.waitUntilExit?()
      }
    }
  }
}
