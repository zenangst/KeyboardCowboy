import Foundation

protocol ConfigurationLocatable: Hashable, Sendable {
  var url: URL { get }
}

struct ConfigurationLocation: ConfigurationLocatable {
  var path: String
  var filename: String
  var url: URL {
    URL(fileURLWithPath: path).appendingPathComponent(filename)
  }

  init(path: String, filename: String) {
    self.path = (path as NSString).expandingTildeInPath
    self.filename = filename
  }
}

struct ConfigurationUserStorage: ConfigurationLocatable {
  var url: URL
}
