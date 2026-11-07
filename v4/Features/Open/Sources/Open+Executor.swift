import Foundation

public extension Open {
  /// Host-provided effects for the legacy open routes. Implementations must be safe
  /// to call concurrently; the host is responsible for any required actor hops.
  protocol Operations: Sendable {
    func openHost() async
    func openFinder(_ path: String, checkCancellation: Bool) async throws
    func openBrowser(_ path: String, application: TargetApplication?, checkCancellation: Bool) async throws
    func openWebApp(_ path: String, application: TargetApplication, checkCancellation: Bool) async throws
    func openGeneric(_ path: String, application: TargetApplication?) async throws
    func isDirectory(_ path: String) async throws -> Bool
  }

  /// Executes the selected route and preserves the legacy runner's fallback scope.
  struct Executor: Sendable {
    private let dispatcher: Dispatcher
    private let operations: any Operations

    public init(hostBundleIdentifier: String, hostBundleURL: URL, operations: any Operations) {
      dispatcher = Dispatcher(hostBundleIdentifier: hostBundleIdentifier, hostBundleURL: hostBundleURL)
      self.operations = operations
    }

    public func run(_ path: String, application: TargetApplication? = nil, checkCancellation: Bool) async throws {
      let route = dispatcher.route(path: path, application: application)
      if route == .host {
        await operations.openHost()
        return
      }

      do {
        switch route {
        case .host:
          return // Handled before entering the fallback scope.
        case .finder:
          try await operations.openFinder(path, checkCancellation: checkCancellation)
        case .browser:
          try await operations.openBrowser(path, application: application, checkCancellation: checkCancellation)
        case .webApp:
          // This route is only selected for an explicit application.
          if let application {
            try await operations.openWebApp(path, application: application, checkCancellation: checkCancellation)
          }
        case .generic:
          try await operations.openGeneric(path, application: application)
        }
      } catch {
        let isDirectory = await (try? operations.isDirectory(path)) ?? false
        if application?.bundleName == "Finder", isDirectory {
          try await operations.openFinder(path, checkCancellation: checkCancellation)
        } else {
          try await operations.openGeneric(path, application: application)
        }
      }
    }
  }
}
