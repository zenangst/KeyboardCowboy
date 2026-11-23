import Foundation

extension Operation {
  struct Generic: Sendable {
    private let system: Open.System
    private let parser = Open.URLParser()

    init(environment: Open.Environment) {
      system = Open.System(environment: environment)
    }

    func callAsFunction(_ path: String, application: Open.TargetApplication?) async throws {
      let applicationURL = application.map { URL(fileURLWithPath: $0.path) }
      try await system.open(parser.parse(path), applicationURL: applicationURL)
    }

    func isDirectory(_ path: String) throws -> Bool {
      try system.isDirectory(path)
    }
  }
}
