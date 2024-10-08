import Foundation

enum ConfigurationMigratorError: Error {
  case fileDoesNotExist(path: String)
  case unableToGetFileAttributes(Error)
  case migrationFailedFrom(URL)
  case migrationFileAlreadyExists(URL)
  case unableToCreateDirectory(URL)
  case unableToCopyFile(URL, URL)
  case unableToGetDataFromFile(URL)
  case comparingFileContentsFailed(URL, URL)
  case unableToRemoveItem(URL)
}

protocol ConfigurationMigratorFileManager {
  func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any]
  func copyItem(at srcURL: URL, to dstURL: URL) throws
  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws
  func dataFromContentsOfFile(atPath path: String) throws(ConfigurationMigratorError) -> Data
  func fileExists(atPath path: String) -> Bool
  func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
  func removeItem(at URL: URL) throws
}

extension FileManager: ConfigurationMigratorFileManager {
  func dataFromContentsOfFile(atPath path: String) throws(ConfigurationMigratorError) -> Data {
    let url = URL(fileURLWithPath: path)
    do {
      return try Data(contentsOf: url)
    } catch {
      throw .unableToGetDataFromFile(url)
    }
  }
}

final class ConfigurationMigrator {
  let legacyUrl: URL
  let fileManager: ConfigurationMigratorFileManager

  init(legacyUrl: URL, fileManager: ConfigurationMigratorFileManager = FileManager.default) {
    self.fileManager = fileManager
    self.legacyUrl = legacyUrl
  }

  func configurationNeedsMigration(at url: URL) throws(ConfigurationMigratorError) -> Bool {
    if url == legacyUrl {
      return !(try isSymbolicLink(atPath: url.relativePath.expandingTildeInPath))
    }

    return false
  }

  func performMigration(from: URL, to: URL) throws(ConfigurationMigratorError) {
    guard fileManager.fileExists(atPath: from.relativePath.expandingTildeInPath) else {
      throw .migrationFailedFrom(from)
    }

    guard !fileManager.fileExists(atPath: to.relativePath.expandingTildeInPath) else {
      throw .migrationFileAlreadyExists(to)
    }

    let path = (to.relativePath as NSString).deletingLastPathComponent

    // Create directory if it does not exist.
    var isDirectory: ObjCBool = true
    if !fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
      let folderUrl = URL(filePath: path)
      do {
        try fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
      } catch {
        throw .unableToCreateDirectory(folderUrl)
      }
    }

    do {
      try fileManager.copyItem(at: from, to: to)
    } catch {
      throw .unableToCopyFile(from, to)
    }

    let fromData = try fileManager.dataFromContentsOfFile(atPath: from.relativePath.expandingTildeInPath)
    let toData = try fileManager.dataFromContentsOfFile(atPath: to.relativePath.expandingTildeInPath)

    // Verify that both files have the same contents.
    if fromData != toData {
      throw .comparingFileContentsFailed(from, to)
    }

    // Remove the old file.
    do {
      try fileManager.removeItem(at: from)
    } catch {
      throw .unableToRemoveItem(from)
    }
  }

  // MARK: Private methods

  private func isSymbolicLink(atPath path: String) throws(ConfigurationMigratorError) -> Bool {
    do {
      if !fileManager.fileExists(atPath: path) {
        throw ConfigurationMigratorError.fileDoesNotExist(path: path)
      }

      let attributes = try fileManager.attributesOfItem(atPath: path)
      if let fileType = attributes[FileAttributeKey.type] as? FileAttributeType {
        return fileType == FileAttributeType.typeSymbolicLink
      }
      return false
    } catch {
      throw .unableToGetFileAttributes(error)
    }
  }
}
