import Foundation

extension String {
  var sanitizedPath: String { _sanitizePath() }

  mutating func sanitizePath() {
    self = _sanitizePath()
  }

  private func _sanitizePath() -> String {
    var path = (self as NSString).expandingTildeInPath
    path = path.replacingOccurrences(of: "", with: "\\ ")
    return path
  }

  public func containsCaseSensitive(_ subject: String) -> Bool {
    self.lowercased().contains(subject.lowercased())
  }
}
