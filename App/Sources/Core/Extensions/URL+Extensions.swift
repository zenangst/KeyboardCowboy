import Foundation

extension URL {
  var expandingTildeInPath: URL { URL(fileURLWithPath: relativePath.expandingTildeInPath) }
}
