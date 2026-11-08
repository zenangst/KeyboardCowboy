import Foundation
import System

public extension FilePath {
  var path: String {
    (string as NSString)
      .expandingTildeInPath
  }
}
