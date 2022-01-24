import Apps
import Foundation

enum StorageError: Error {
  case unableToReadContents
}

final class Storage {
  var configuration: StorageConfiguration

  internal init(_ configuration: StorageConfiguration) {
    self.configuration = configuration
  }

  func load() async throws -> [WorkflowGroup] {
    let fileUrl = URL(fileURLWithPath: configuration.path)
      .appendingPathComponent(configuration.filename)
    let decoder = JSONDecoder()
    let fileManager = FileManager()

    guard let data = fileManager.contents(atPath: fileUrl.path),
          !data.isEmpty else {
      throw StorageError.unableToReadContents
    }

    return try decoder.decode([WorkflowGroup].self, from: data)
  }
}
