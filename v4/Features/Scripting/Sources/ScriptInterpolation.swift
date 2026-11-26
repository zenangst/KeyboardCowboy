import Foundation

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
