import Foundation

public extension Open {
  /// Generic workspace opening and directory metadata used by the executor fallback.
  struct Generic: Sendable {
    private let system: System
    private let parser = URLParser()

    public init() {
      system = System(environment: .production)
    }

    init(environment: Environment) {
      system = System(environment: environment)
    }

    public func open(_ path: String, application: TargetApplication? = nil) async throws {
      let applicationURL = application.map { URL(fileURLWithPath: $0.path) }
      try await system.open(parser.parse(path), applicationURL: applicationURL)
    }

    public func isDirectory(_ path: String) throws -> Bool {
      try system.isDirectory(path)
    }
  }
}
