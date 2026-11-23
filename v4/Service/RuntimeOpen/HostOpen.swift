import AppleScriptRuntime
import Commands
import Foundation
import OpenFeature

/// Service-side Open composition. The caller resolves the command path and
/// supplies host interception.
package struct HostOpen: Sendable {
  package enum Event: String, Sendable {
    case tabSearchStarted = "tab search started"
    case tabSearchNoMatch = "tab search found no matching tab"
    case tabSearchAutomationDenied = "tab search was denied Automation permission"
    case tabSearchFailed = "tab search script failed"
    case browserSucceeded = "browser route succeeded"
    case browserFailed = "browser route failed"
    case genericOpenStarted = "generic open started"
  }

  private let executor: Open.Executor

  package init(
    hostBundleIdentifier: String,
    hostBundleURL: URL,
    openHost: @escaping @Sendable () async -> Void,
    openWebApp: @escaping @Sendable (String, Open.TargetApplication, Bool) async throws -> Void = { [webApp = Open.WebApp()]
      path, application, _ in
        try await webApp.open(path, application: application)
    },
    record: @escaping @Sendable (Event) -> Void = { _ in },
  ) {
    let browser = Open.Browser(tabSearch: .init { _, source, checkCancellation in
      record(.tabSearchStarted)
      do {
        return try await Self.executeScript(source, checkCancellation: checkCancellation)
      } catch AppleScriptRuntime.NSAppleScript.Error.unableToExecute(let error)
        where (error as NSError).code == -1743 {
        record(.tabSearchAutomationDenied)
        throw AppleScriptRuntime.NSAppleScript.Error.unableToExecute(error)
      } catch {
        if !(error is CancellationError) { record(.tabSearchFailed) }
        throw error
      }
    })
    let finder = Open.Finder { _, source, checkCancellation in
      _ = try await Self.executeScript(source, checkCancellation: checkCancellation)
    }
    let generic = Open.Generic()
    executor = Open.Executor(
      hostBundleIdentifier: hostBundleIdentifier,
      hostBundleURL: hostBundleURL,
      operations: .init(
        openHost: openHost,
        openFinder: { try await finder.open($0, checkCancellation: $1) },
        openBrowser: { path, application, checkCancellation in
          do {
            try await browser.open(path, application: application, checkCancellation: checkCancellation)
            record(.browserSucceeded)
          } catch {
            if error is Open.BrowserTabSearch.SearchError { record(.tabSearchNoMatch) }
            record(.browserFailed)
            throw error
          }
        },
        openWebApp: openWebApp,
        openGeneric: {
          record(.genericOpenStarted)
          try await generic.open($0, application: $1)
        },
        isDirectory: { try generic.isDirectory($0) },
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
