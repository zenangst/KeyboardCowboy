import CowboyCore
import Foundation
import System

/// The feature-level execution request. Persistence and command metadata belong to the host.
public struct ScriptRequest: Sendable {
  public enum Kind: Sendable {
    case appleScript(Variant)
    case shellScript
  }

  public enum Variant: Sendable {
    case regular, jxa
  }

  public enum Source: Sendable {
    case inline(String), path(String)
  }

  public let id: String
  public let kind: Kind
  public let source: Source

  public init(id: String, kind: Kind, source: Source) {
    self.id = id
    self.kind = kind
    self.source = source
  }
}

/// Ordered literal replacements supplied by the host, not process environment variables.
/// Tokens are replaced in order, including occurrences introduced by earlier replacements.
public struct ScriptInterpolation: Sendable {
  public struct Replacement: Sendable {
    public let token: String
    public let value: String

    public init(token: String, value: String) {
      self.token = token
      self.value = value
    }
  }

  public let replacements: [Replacement]

  public init(_ replacements: [Replacement] = []) {
    self.replacements = replacements
  }

  public func apply(to input: String) -> String {
    replacements.reduce(input) { $0.replacingOccurrences(of: $1.token, with: $1.value) }
  }
}

/// Dispatches requests without defining host cancellation or subprocess parity policies.
/// Shell and JXA calls run synchronously on this actor: a long-running command
/// delays later requests and cache invalidation. Cancellation terminates and reaps
/// the direct subprocess, but not its descendants. Output after the post-exit drain
/// deadline may be truncated.
/// Nonzero subprocess exits throw `ScriptProcessError` with status and raw output.
/// Hosts must explicitly clear the AppleScript cache when lifecycle policy requires it.
public actor ScriptCommandDispatcher {
  /// Execution boundaries can be substituted without invoking scripts or the filesystem.
  public struct Routes: Sendable {
    public var appleScriptInline: @Sendable (String, String) async throws -> String?
    public var appleScriptFile: @Sendable (String, String) async throws -> String?
    public var jxaInline: @Sendable (String) throws -> String?
    public var shellInline: @Sendable (String) throws -> String?
    public var shellFile: @Sendable (String) throws -> String?
    public var clearAppleScriptCache: @Sendable () async -> Void

    public init(
      appleScriptInline: @escaping @Sendable (String, String) async throws -> String?,
      appleScriptFile: @escaping @Sendable (String, String) async throws -> String?,
      jxaInline: @escaping @Sendable (String) throws -> String?,
      shellInline: @escaping @Sendable (String) throws -> String?,
      shellFile: @escaping @Sendable (String) throws -> String?,
      clearAppleScriptCache: @escaping @Sendable () async -> Void
    ) {
      self.appleScriptInline = appleScriptInline
      self.appleScriptFile = appleScriptFile
      self.jxaInline = jxaInline
      self.shellInline = shellInline
      self.shellFile = shellFile
      self.clearAppleScriptCache = clearAppleScriptCache
    }
  }

  private let routes: Routes

  public init(routes: Routes) {
    self.routes = routes
  }

  /// The same AppleScript executor is retained for all requests and cache invalidation.
  @MainActor public init(_ environment: Core.Environment) {
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
      clearAppleScriptCache: { await appleScript.clearCache() }
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
