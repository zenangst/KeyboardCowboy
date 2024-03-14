import Foundation

protocol StoringConfiguration: Hashable, Sendable {
  var url: URL { get }
}

struct StorageConfiguration: StoringConfiguration {
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

struct UserStorageConfiguration: StoringConfiguration {
  var url: URL
}
