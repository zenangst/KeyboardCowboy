import Foundation

public extension Core {
  final class Process {
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

    enum Mode {
      case production(Foundation.Process)
      #if DEBUG
      case testing(Storage)
      #endif
    }

    let mode: Mode
    public let launchStyle: LaunchStyle

    public var arguments: [String]? {
      get {
        switch mode {
        case .production(let process): process.arguments
        #if DEBUG
        case .testing(let storage): storage.arguments
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.arguments = newValue
        #if DEBUG
        case .testing(let storage): storage.arguments = newValue
        #endif
        }
      }
    }

    public var currentDirectoryURL: URL? {
      get {
        switch mode {
        case .production(let process): process.currentDirectoryURL
        #if DEBUG
        case .testing(let storage): storage.currentDirectoryURL
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.currentDirectoryURL = newValue
        #if DEBUG
        case .testing(let storage): storage.currentDirectoryURL = newValue
        #endif
        }
      }
    }

    public var executableURL: URL? {
      get {
        switch mode {
        case .production(let process): process.executableURL
        #if DEBUG
        case .testing(let storage): storage.executableURL
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.executableURL = newValue
        #if DEBUG
        case .testing(let storage): storage.executableURL = newValue
        #endif
        }
      }
    }

    public var environment: [String: String]? {
      get {
        switch mode {
        case .production(let process): process.environment
        #if DEBUG
        case .testing(let storage): storage.environment
        #endif
        }
      }
      set {
        switch mode {
        case .production(let process): process.environment = newValue
        #if DEBUG
        case .testing(let storage): storage.environment = newValue
        #endif
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
      #if DEBUG
      case .testing: .testing(Storage())
      #endif
      }
    }

    public func run() throws {
      switch mode {
      case .production(let process):
        try process.run()
      #if DEBUG
      case .testing:
        try Testing.mock.run?()
      #endif
      }
    }

    public func waitUntilExit() {
      switch mode {
      case .production(let process):
        process.waitUntilExit()
      #if DEBUG
      case .testing:
        Testing.mock.waitUntilExit?()
      #endif
      }
    }
  }
}
