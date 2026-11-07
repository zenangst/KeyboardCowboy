import Foundation

public extension Open {
  /// Retargets Finder's front window. The host executes the script with a fresh
  /// user-environment-resolving snapshot and an empty runtime dictionary.
  struct Finder: Sendable {
    private let executeScript: @Sendable (_ name: String, _ source: String, _ checkCancellation: Bool) async throws -> Void
    private let parser = URLParser()

    public init(executeScript: @escaping @Sendable (_ name: String, _ source: String, _ checkCancellation: Bool) async throws -> Void) {
      self.executeScript = executeScript
    }

    public func open(_ path: String, checkCancellation: Bool) async throws {
      let escapedPath = parser.parse(path).path
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
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
