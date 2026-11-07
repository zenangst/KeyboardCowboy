import Foundation

public extension Open {
  /// Browser reuse orchestration. The host-supplied AX operation must enumerate
  /// windows, raise the first whose web-area URL contains the supplied path, and
  /// return whether it matched. AX errors must be thrown rather than suppressed.
  struct Browser: Sendable {
    private let system: System
    private let launch: BrowserLaunch
    private let tabSearch: BrowserTabSearch
    private let raiseMatchingWindow: @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool

    public init(
      tabSearch: BrowserTabSearch,
      raiseMatchingWindow: @escaping @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool,
    ) {
      self.init(environment: .production, tabSearch: tabSearch, raiseMatchingWindow: raiseMatchingWindow)
    }

    init(
      environment: Environment,
      tabSearch: BrowserTabSearch,
      raiseMatchingWindow: @escaping @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool,
    ) {
      system = System(environment: environment)
      launch = BrowserLaunch(environment: environment)
      self.tabSearch = tabSearch
      self.raiseMatchingWindow = raiseMatchingWindow
    }

    public func open(_ path: String, application: TargetApplication? = nil, checkCancellation: Bool) async throws {
      let identifier = application?.bundleIdentifier ?? "com.apple.Safari"
      guard let process = system.firstRunningProcess(bundleIdentifier: identifier) else {
        try await launch.open(path, application: application)
        return
      }

      if try await raiseMatchingWindow(process, path) {
        system.activate(processIdentifier: process)
      } else {
        try await tabSearch.search(
          path,
          applicationName: application?.displayName ?? "Safari",
          checkCancellation: checkCancellation,
        )
      }
    }
  }
}
