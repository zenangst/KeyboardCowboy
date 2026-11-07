import Foundation

public extension Open {
  /// Searches a running browser's tabs after AX matching fails. The host executes
  /// the script with a fresh snapshot without user-environment resolution and an
  /// empty runtime dictionary. Only the exact result "-1" indicates no match.
  struct BrowserTabSearch: Sendable {
    public enum SearchError: Error, Equatable, Sendable {
      case couldNotFindOpenURL
    }

    private let executeScript: @Sendable (String, String, Bool) async throws -> String?

    public init(executeScript: @escaping @Sendable (
      _ name: String,
      _ source: String,
      _ checkCancellation: Bool,
    ) async throws -> String?) {
      self.executeScript = executeScript
    }

    public func search(_ path: String, applicationName: String, checkCancellation: Bool) async throws {
      let url = Open.escapeAppleScriptLiteral(path)
      let name = Open.escapeAppleScriptLiteral(applicationName)
      let source = """
      property matchingURL : "\(url)"
      tell application "\(name)"
      activate
      set theURLs to (get URL of every tab of every window)
      repeat with x from 1 to length of theURLs
      set tmp to item x of theURLs
      repeat with y from 1 to length of tmp
      if item y of tmp contains matchingURL then
          set the index of window x to 1
          tell window 1
              if index of current tab is not y then set current tab to tab y
              return 0
          end tell
      end if
      end repeat
      end repeat
      return -1
      end tell
      """
      let result = try await executeScript(UUID().uuidString, source, checkCancellation)
      if result == "-1" { throw SearchError.couldNotFindOpenURL }
    }
  }
}
