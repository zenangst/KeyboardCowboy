import AccessibilitySystem
import Foundation

extension Operation {
  struct Browser: Sendable {
    private let system: Open.System
    private let launch: Open.BrowserLaunch
    private let tabSearch: Open.BrowserTabSearch
    private let raiseMatchingWindow: @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool

    init(
      tabSearch: Open.BrowserTabSearch,
      accessibility: AccessibilitySystem.Client,
    ) {
      self.init(environment: .production, tabSearch: tabSearch, raiseMatchingWindow: { pid, path in
        try await accessibility.withApplication(processIdentifier: pid) { session in
          try Self.raiseMatchingWindow(
            path: path,
            windows: { try session.windows() },
            firstWebAreaURL: { window in
              try session.firstValue(of: .url, atRole: .webArea, under: window,
                                     includingRoot: true, missingValue: .skipNoValueOrUnsupported)
            },
            raise: { try session.perform(.raise, on: $0) },
          )
        }
      })
    }

    init(
      environment: Open.Environment,
      tabSearch: Open.BrowserTabSearch,
      raiseMatchingWindow: @escaping @Sendable (_ processIdentifier: Int32, _ path: String) async throws -> Bool,
    ) {
      system = Open.System(environment: environment)
      launch = Open.BrowserLaunch(environment: environment)
      self.tabSearch = tabSearch
      self.raiseMatchingWindow = raiseMatchingWindow
    }

    static func raiseMatchingWindow<Window>(
      path: String,
      windows: () throws -> [Window],
      firstWebAreaURL: (Window) throws -> URL?,
      raise: (Window) throws -> Void,
    ) throws -> Bool {
      // Use AX order without requiring a Core Graphics window ID. Compare only
      // the first web-area URL per window, not any matching descendant.
      for window in try windows() {
        guard let url = try firstWebAreaURL(window), url.absoluteString.contains(path) else { continue }
        try raise(window)
        return true
      }
      return false
    }

    func callAsFunction(_ path: String, application: Open.TargetApplication?, checkCancellation: Bool) async throws {
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
