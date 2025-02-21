import Foundation

extension URL {
  var expandingTildeInPath: URL { URL(fileURLWithPath: relativePath.expandingTildeInPath) }

  var isWebURL: Bool {
    scheme == "http" || scheme == "https"
  }
}
