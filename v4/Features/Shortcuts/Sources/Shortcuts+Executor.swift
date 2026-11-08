import ProcessSystem
import Foundation
import CowboyCore

public enum Shortcuts {
  public enum CancellationPolicy: Sendable {
    case checkBeforeLaunch
    case ignore
  }

  public enum ExecutionError: Error, Equatable {
    case executionFailed(String)
  }

  public struct Executor: Sendable {
    private let execute: @Sendable (String) async throws -> String?

    public init() {
      self.init(environment: .production)
    }

    private init(environment: Core.Environment) {
      self.execute = { identifier in
        #if DEBUG
        let mock = Core.Process.Testing.mock
        #endif
        return try await Task.detached {
          #if DEBUG
          return try Core.Process.Testing.$mock.withValue(mock) {
            try runProcess(identifier: identifier, environment: environment)
          }
          #else
          return try runProcess(identifier: identifier, environment: environment)
          #endif
        }.value
      }
    }

    #if DEBUG
    init(execute: @escaping @Sendable (String) async throws -> String?) {
      self.execute = execute
    }

    static func testing() -> Self { Self(environment: .testing) }
    #endif

    public func run(_ identifier: String, cancellation: CancellationPolicy) async throws -> String? {
      if cancellation == .checkBeforeLaunch { try Task.checkCancellation() }
      return try await execute(identifier)
    }
  }
}

private func runProcess(identifier: String, environment: Core.Environment) throws -> String? {
  let process = Core.Process(environment, launchStyle: .headless(identifier))
  process.executableURL = URL(filePath: "/usr/bin/shortcuts")
  process.arguments = ["run", identifier]
  process.standardOutput = Core.Pipe(environment)
  process.standardError = Core.Pipe(environment)
  let output = try process.runAndCaptureOutputUnbounded()
  if process.terminationStatus != 0 {
    throw Shortcuts.ExecutionError.executionFailed(output.stderr.flatMap { String(data: $0, encoding: .utf8) } ?? "")
  }
  return output.stdout.flatMap { String(data: $0, encoding: .utf8) }
}
