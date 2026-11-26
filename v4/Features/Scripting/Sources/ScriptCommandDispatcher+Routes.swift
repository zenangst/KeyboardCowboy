public extension ScriptCommandDispatcher {
  /// Execution boundaries can be substituted without invoking scripts or the filesystem.
  struct Routes: Sendable {
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
      clearAppleScriptCache: @escaping @Sendable () async -> Void,
    ) {
      self.appleScriptInline = appleScriptInline
      self.appleScriptFile = appleScriptFile
      self.jxaInline = jxaInline
      self.shellInline = shellInline
      self.shellFile = shellFile
      self.clearAppleScriptCache = clearAppleScriptCache
    }
  }
}
