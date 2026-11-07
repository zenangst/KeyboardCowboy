import Cocoa
import CowboyCore
import System

public extension AppleScript {
  /// Uses the main thread as required by NSAppleScript and caches scripts by key only.
  /// Reusing a key reuses its compiled script even when the source or path changes.
  /// Clear the cache when the host requires recompilation. Script execution can
  /// block the main thread and does not stop on task cancellation. Reentrant
  /// execution is rejected; a reentrant cache clear takes effect after execution.
  @MainActor final class Executor {
    public enum ExecutionError: Error, Equatable, Sendable {
      case reentrantExecution
    }

    private var cache: Cache
    private let env: Core.Environment
    private var isExecuting = false
    private var shouldClearCache = false

    public init(_ env: Core.Environment) {
      self.cache = Cache()
      self.env = env
    }

    /// Invalidates all compiled scripts, deferring invalidation during execution.
    public func clearCache() {
      if isExecuting {
        shouldClearCache = true
      } else {
        cache.clear()
      }
    }

    public func execute(_ filePath: FilePath, key: String) throws -> String? {
      try beginExecution()
      defer { finishExecution() }
      if let appleScript = cache.get(for: key) {
        var errorDictionary: NSDictionary?
        return try appleScript.executeAndReturnError(&errorDictionary).stringValue
      }

      var errorDictionary: NSDictionary?

      let appleScript = try Core.NSAppleScript(env, contentsOf: URL(filePath: filePath.path), error: &errorDictionary)
      try appleScript.compileAndReturnError(&errorDictionary)
      let descriptor = try appleScript.executeAndReturnError(&errorDictionary)

      cache.set(appleScript, for: key)

      return descriptor.stringValue
    }

    public func execute(_ source: String, key: String) throws -> String? {
      try beginExecution()
      defer { finishExecution() }
      if let appleScript = cache.get(for: key) {
        var errorDictionary: NSDictionary?
        return try appleScript.executeAndReturnError(&errorDictionary).stringValue
      }

      var errorDictionary: NSDictionary?

      let appleScript = try Core.NSAppleScript(env, source: source)
      try appleScript.compileAndReturnError(&errorDictionary)
      let descriptor = try appleScript.executeAndReturnError(&errorDictionary)

      cache.set(appleScript, for: key)

      return descriptor.stringValue
    }

    private func beginExecution() throws {
      guard !isExecuting else { throw ExecutionError.reentrantExecution }
      isExecuting = true
    }

    private func finishExecution() {
      if shouldClearCache {
        cache.clear()
        shouldClearCache = false
      }
      isExecuting = false
    }
  }
}
