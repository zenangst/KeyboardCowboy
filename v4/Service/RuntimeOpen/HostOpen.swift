import AppleScriptRuntime
import Commands
import Foundation
import OpenFeature

/// Service-side Open composition. The caller resolves the command path and
/// supplies host interception and web-app behavior.
package struct HostOpen: Sendable {
  private let executor: Open.Executor

  package init(
    hostBundleIdentifier: String,
    hostBundleURL: URL,
    openHost: @escaping @Sendable () async -> Void,
    openWebApp: @escaping @Sendable (String, Open.TargetApplication, Bool) async throws -> Void,
  ) {
    let browser = Open.Browser(tabSearch: .init { _, source, checkCancellation in
      try await Self.executeScript(source, checkCancellation: checkCancellation)
    })
    let finder = Open.Finder { _, source, checkCancellation in
      _ = try await Self.executeScript(source, checkCancellation: checkCancellation)
    }
    executor = Open.Executor(
      hostBundleIdentifier: hostBundleIdentifier,
      hostBundleURL: hostBundleURL,
      operations: .init(
        finder: finder,
        openHost: openHost,
        openBrowser: { try await browser.open($0, application: $1, checkCancellation: $2) },
        openWebApp: openWebApp,
      ),
    )
  }

  package func run(_ command: Command.Open, resolvedPath: String, checkCancellation: Bool) async throws {
    try await executor.run(command, resolvedPath: resolvedPath, checkCancellation: checkCancellation)
  }

  @MainActor
  private static func executeScript(_ source: String, checkCancellation: Bool) throws -> String? {
    if checkCancellation { try Task.checkCancellation() }
    let script = try AppleScriptRuntime.NSAppleScript(.production, source: source)
    try script.compileAndReturnError(nil)
    if checkCancellation { try Task.checkCancellation() }
    let result = try script.executeAndReturnError(nil).stringValue
    if checkCancellation { try Task.checkCancellation() }
    return result
  }
}
