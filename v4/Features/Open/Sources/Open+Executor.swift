import Foundation

public extension Open {
  /// Executes the selected route and preserves the legacy runner's fallback scope.
  struct Executor: Sendable {
    private let dispatcher: Dispatcher
    private let operations: Operations

    public init(hostBundleIdentifier: String, hostBundleURL: URL, operations: Operations) {
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
          try await operations.openFinder(path, checkCancellation)
        case .browser:
          try await operations.openBrowser(path, application, checkCancellation)
        case .webApp:
          // This route is only selected for an explicit application.
          if let application {
            try await operations.openWebApp(path, application, checkCancellation)
          }
        case .generic:
          try await operations.openGeneric(path, application)
        }
      } catch {
        let isDirectory = await (try? operations.isDirectory(path)) ?? false
        if application?.bundleName == "Finder", isDirectory {
          try await operations.openFinder(path, checkCancellation)
        } else {
          try await operations.openGeneric(path, application)
        }
      }
    }
  }
}
