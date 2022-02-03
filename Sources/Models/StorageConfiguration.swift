import Foundation

struct StorageConfiguration {
  var path: String
  var filename: String
  var url: URL {
    URL(fileURLWithPath: path).appendingPathComponent(filename)
  }

  internal init(path: String, filename: String) {
    self.path = (path as NSString).expandingTildeInPath
    self.filename = filename
  }
}
