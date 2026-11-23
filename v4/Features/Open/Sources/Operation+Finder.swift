extension Operation {
  struct Finder: Sendable {
    private let executeScript: @Sendable (String, String, Bool) async throws -> Void
    private let parser = Open.URLParser()

    init(executeScript: @escaping @Sendable (String, String, Bool) async throws -> Void) {
      self.executeScript = executeScript
    }

    func callAsFunction(_ path: String, checkCancellation: Bool) async throws {
      let escapedPath = Open.escapeAppleScriptLiteral(parser.parse(path).path)
      let source = """
      tell application "Finder"
        set the target of the front Finder window to folder ("\(escapedPath)" as POSIX file)
      end tell
      """
      if checkCancellation { try Task.checkCancellation() }
      try await executeScript("Open folder in Finder: \(path)", source, checkCancellation)
    }
  }
}
