import Foundation

public extension Open {
  /// Opens a URL when the browser is not running. The caller must first check
  /// running-app state; this operation does not perform browser reuse.
  struct BrowserLaunch: Sendable {
    private let system: System

    public init() {
      system = System(environment: .production)
    }

    init(environment: Environment) {
      system = System(environment: environment)
    }

    public func open(_ path: String, application: TargetApplication? = nil) async throws {
      guard let url = URL(string: path) else { return }
      if let application {
        try await system.open(url, applicationURL: URL(fileURLWithPath: application.path))
      } else {
        _ = system.openDefault(url)
      }
    }
  }
}
