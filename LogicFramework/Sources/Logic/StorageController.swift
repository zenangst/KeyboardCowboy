import Foundation

public protocol StorageControlling {
  func load() throws ->  [Group]
  func save(_ groups: [Group]) throws
}

enum StorageControllingError: Error {
  case fileToLoadData
}

class StorageController: StorageControlling {
  var path: String
  var fileName: String

  init(path: String, fileName: String) {
    self.path = (path as NSString).expandingTildeInPath
    self.fileName = fileName
  }

  func load() throws -> [Group] {
    let fileUrl = URL(fileURLWithPath: path).appendingPathComponent(fileName)
    let decoder = JSONDecoder()
    let fileManager = FileManager()

    guard let data = fileManager.contents(atPath: fileUrl.path) else {
      throw StorageControllingError.fileToLoadData
    }

    return try decoder.decode([Group].self, from: data)
  }

  func save(_ groups: [Group]) throws {
    let fileUrl = URL(fileURLWithPath: path).appendingPathComponent(fileName)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(groups)
    let fileManager = FileManager()
    fileManager.createFile(atPath: fileUrl.path, contents: data, attributes: nil)
  }
}
