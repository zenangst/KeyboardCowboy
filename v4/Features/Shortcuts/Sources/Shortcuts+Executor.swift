import Foundation
import RuntimeEnvironment

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

    private init(environment: RuntimeEnvironment.Mode) {
      self.execute = { identifier in
        let output = try await launchShortcuts(["run", identifier], environment: environment)
        if output.status != 0 {
          throw ExecutionError.executionFailed(output.stderr.flatMap { String(data: $0, encoding: .utf8) } ?? "")
        }
        return output.stdout.flatMap { String(data: $0, encoding: .utf8) }
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
