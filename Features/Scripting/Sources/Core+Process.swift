import CowboyCore
import Foundation

extension Core {
  final class Process {
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

    enum Mode {
      case production(Foundation.Process)
      case testing(Storage)
    }

    enum Kind {
      case headless
      case shell
    }

    let mode: Mode
    let kind: Kind

    var arguments: [String]? {
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

    var currentDirectoryURL: URL? {
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

    var executableURL: URL? {
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

    var environment: [String: String]? {
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

    var standardError: Core.Pipe? {
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

    var standardOutput: Core.Pipe? {
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

    var source: String

    init(_ env: Environment, result: ShellScript.Parser.Result) {
      switch result {
      case .headless(let source):
        self.source = source
        self.kind = .headless
      case .shell(let source):
        self.source = source
        self.kind = .shell
      }

      self.mode = switch env {
      case .production: .production(Foundation.Process())
      case .testing: .testing(Storage())
      }
    }

    func run() throws {
      switch mode {
      case .production(let process):
        try process.run()
      case .testing:
        try Testing.mock.run?()
      }
    }

    func waitUntilExit() {
      switch mode {
      case .production(let process):
        process.waitUntilExit()
      case .testing:
        Testing.mock.waitUntilExit?()
      }
    }
  }
}
