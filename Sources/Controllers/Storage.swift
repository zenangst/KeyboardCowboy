import Apps
import Foundation

enum StorageError: Error {
  case unableToReadContents
}

final class Storage {
  var path: String
  var fileName: String

  init(path: String, fileName: String) {
    self.path = (path as NSString).expandingTildeInPath
    self.fileName = fileName
  }

  func load() async throws -> [WorkflowGroup] {
    let fileUrl = URL(fileURLWithPath: path).appendingPathComponent(fileName)
    let decoder = JSONDecoder()
    let fileManager = FileManager()

    guard let data = fileManager.contents(atPath: fileUrl.path),
          !data.isEmpty else {
      throw StorageError.unableToReadContents
    }

    return try decoder.decode([WorkflowGroup].self, from: data)
  }
}
