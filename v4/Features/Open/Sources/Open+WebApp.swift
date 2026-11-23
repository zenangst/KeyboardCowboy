import AccessibilitySystem
import Foundation

public extension Open {
  struct WebApp: Sendable {
    public enum Outcome: Sendable {
      case notOpened, pollingSkipped, noMatch, raised
    }

    private let system = System(environment: .production)
    private let accessibility = AccessibilitySystem.Client()

    public init() {}

    @discardableResult
    public func open(_ path: String, application: TargetApplication) async throws -> Outcome {
      guard let pid = system.firstRunningProcess(bundleIdentifier: application.bundleIdentifier),
            let url = URL(string: path) else { return .notOpened }

      try await system.open(url, applicationURL: URL(fileURLWithPath: application.path))
      let count = try await accessibility.withApplication(processIdentifier: pid) { try $0.windows().count }
      return try await Self.poll(
        initialWindowCount: count,
        wait: { try await Task.sleep(for: .milliseconds(100)) },
      ) {
        try await accessibility.withApplication(processIdentifier: pid) { session in
          try Self.activateMatchingWindows(
            path: path,
            windows: session.windows(),
            firstWebAreaURL: { window in
              try session.firstValue(of: .url, atRole: .webArea, under: window,
                                     includingRoot: true, missingValue: .skipNoValueOrUnsupported)
            },
            setMain: { try session.write(.main, value: true, to: $0) },
            raise: { try session.perform(.raise, on: $0) },
          )
        }
      }
    }

    @discardableResult
    static func poll(
      initialWindowCount: Int,
      wait: () async throws -> Void,
      match: () async throws -> Bool,
    ) async throws -> Outcome {
      guard initialWindowCount > 1 else { return .pollingSkipped }

      for _ in 0 ..< 10 {
        try await wait()
        if try await match() { return .raised }
      }
      return .noMatch
    }

    static func activateMatchingWindows<Window>(
      path: String,
      windows: [Window],
      firstWebAreaURL: (Window) throws -> URL?,
      setMain: (Window) throws -> Void,
      raise: (Window) throws -> Void,
    ) throws -> Bool {
      var matched = false
      for window in windows {
        guard let url = try firstWebAreaURL(window), url.absoluteString.contains(path) else { continue }

        try setMain(window)
        try raise(window)
        matched = true
      }
      return matched
    }
  }
}
