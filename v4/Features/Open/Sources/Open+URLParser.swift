import Foundation

public extension Open {
  /// Preserves the legacy open runner's URL parsing and browser eligibility rules.
  struct URLParser: Sendable {
    public init() {}

    /// File URLs are treated as literal paths, and tildes are not expanded.
    public func parse(_ path: String) -> URL {
      guard let url = URL(string: path), url.scheme != nil, !url.isFileURL else {
        return URL(fileURLWithPath: path)
      }

      return url
    }

    /// Browser reuse applies only to URLs with a host that are not file URLs.
    public func isBrowserEligible(_ path: String) -> Bool {
      guard let url = URL(string: path) else { return false }

      return url.host != nil && !url.isFileURL
    }
  }
}
