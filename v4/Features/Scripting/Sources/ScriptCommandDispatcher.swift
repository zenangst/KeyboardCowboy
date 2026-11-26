import FileSystem
import Foundation
import RuntimeEnvironment
import System

/// Dispatches requests without defining host cancellation or subprocess parity policies.
/// Shell and JXA calls run synchronously on this actor: a long-running command
/// delays later requests and cache invalidation. Cancellation terminates and reaps
/// the direct subprocess, but not its descendants. Output after the post-exit drain
/// deadline may be truncated.
/// Nonzero subprocess exits throw `ScriptProcessError` with status and raw output.
/// Hosts must explicitly clear the AppleScript cache when lifecycle policy requires it.
public actor ScriptCommandDispatcher {
  private let routes: Routes

  public init(routes: Routes) {
    self.routes = routes
  }

  /// The same AppleScript executor is retained for all requests and cache invalidation.
  @MainActor public init(_ environment: RuntimeEnvironment.Mode) {
    let appleScript = AppleScript.Executor(environment)
    self.routes = Routes(
      appleScriptInline: { source, key in try await appleScript.execute(source, key: key) },
      appleScriptFile: { path, key in
        try await appleScript.execute(FilePath(path), key: key)
      },
      jxaInline: { source in try JXA.Executor(environment).execute(source).0 },
      shellInline: { source in
        try ShellScript.Executor(environment).execute(ShellScript.Builder(environment).build(source))
      },
      shellFile: { path in try ShellScript.Executor(environment).executeFile(at: path) },
      clearAppleScriptCache: { await appleScript.clearCache() },
    )
  }

  public func clearAppleScriptCache() async {
    await routes.clearAppleScriptCache()
  }

  public func execute(_ request: ScriptRequest, interpolation: ScriptInterpolation = .init()) async throws -> String? {
    try Task.checkCancellation()
    let output: String?
    do {
      switch (request.kind, request.source) {
      case let (.appleScript, .path(path)):
        // The legacy host routes JXA files through AppleScript too, without interpolation.
        output = try await routes.appleScriptFile((path as NSString).expandingTildeInPath, request.id)
      case let (.appleScript(.regular), .inline(source)):
        output = try await routes.appleScriptInline(interpolation.apply(to: source), request.id)
      case let (.appleScript(.jxa), .inline(source)):
        output = try routes.jxaInline(interpolation.apply(to: source))
      case let (.shellScript, .inline(source)):
        output = try routes.shellInline(interpolation.apply(to: source))
      case let (.shellScript, .path(path)):
        output = try routes.shellFile(interpolation.apply(to: path))
      }
    } catch {
      try Task.checkCancellation()
      throw error
    }
    try Task.checkCancellation()
    return output
  }
}
