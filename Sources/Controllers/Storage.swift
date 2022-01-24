import Apps
import Foundation

enum StorageError: Error {
  case unableToReadContents
  case unableToSaveContents(Error)
}

final class Storage {
  var configuration: StorageConfiguration

  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileManager: FileManager

  internal init(_ configuration: StorageConfiguration,
                decoder: JSONDecoder = .init(),
                encoder: JSONEncoder = .init(),
                fileManager: FileManager = .init()
  ) {
    self.configuration = configuration
    self.encoder = encoder
    self.decoder = decoder
    self.fileManager = fileManager
  }

  func load() async throws -> [WorkflowGroup] {
    guard let data = fileManager.contents(atPath: configuration.url.path),
          !data.isEmpty else {
      throw StorageError.unableToReadContents
    }

    return try decoder.decode([WorkflowGroup].self, from: data)
  }

  func save(_ groups: [WorkflowGroup]) throws {
    encoder.outputFormatting = .prettyPrinted
    do {
      let data = try encoder.encode(groups)
      fileManager.createFile(atPath: configuration.url.path, contents: data, attributes: nil)
    } catch let error {
      throw StorageError.unableToSaveContents(error)
    }
  }
}
