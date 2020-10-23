import Foundation

extension String {
  var sanitizedPath: String { _sanitizePath() }

  mutating func sanitizePath() {
    self = _sanitizePath()
  }

  /// Expand the tile character used in the path & replace any escaped spaces
  ///
  /// - Returns: A new string that expanded and has no escaped whitespace
  private func _sanitizePath() -> String {
    var path = (self as NSString).expandingTildeInPath
    path = path.replacingOccurrences(of: "", with: "\\ ")
    return path
  }

  /// Check if the current string contains a subject string.
  ///
  /// `.lowercased` is applied to both subjects in order to ensure
  /// case-insensitivity.
  ///
  /// - Parameter subject: The string that should be used as the argument
  ///                      for `contains()`
  /// - Returns: True if self contains the subject string.
  public func containsCaseSensitive(_ subject: String) -> Bool {
    self.lowercased().contains(subject.lowercased())
  }
}
