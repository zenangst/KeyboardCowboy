import Foundation
@testable import Keyboard_Cowboy
import XCTest

final class ConfigurationMigratorTests: XCTestCase {
  func testConfigurationWithLegacyConfiguration() throws {
    let config = ConfigurationLocation.legacy
    let migrator = ConfigurationMigrator(legacyUrl: config.url)

    XCTAssertTrue(try migrator.configurationNeedsMigration(at: config.url))
  }

  func testConfigurationWhereFileExistsThatIsNotASymbolicLink() throws {
    let path = ("~/.somefile" as NSString).expandingTildeInPath
    let url = URL(fileURLWithPath: path)
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { _, _ in XCTFail("Should not try and copy a file.") },
      createFolder: { _ in XCTFail("Should not check if the folder exists.") },
      data: { _ in
        XCTFail("Should not check file for data.")
        return Data()
      },
      folderExists: { _ in XCTFail("Should not check if the folder exists."); return false },
      fileExists: { _ in true },
      removeItem: { _ in XCTFail("Should not try and remove items.") })
    let migrator = ConfigurationMigrator(legacyUrl: url, fileManager: fileManager)

    XCTAssertTrue(try migrator.configurationNeedsMigration(at: url))
  }

  // Don't try and perform a migration if the user has already created their own symbolic link.
  func testConfigurationWhereFileExistsAndIsASymbolicLink() throws {
    let path = ("~/.somefile" as NSString).expandingTildeInPath
    let url = URL(fileURLWithPath: path)
    let fileManager = ConfigurationFileManager(
      attributes: [FileAttributeKey.type: FileAttributeType.typeSymbolicLink],
      copyItem: { _, _ in XCTFail("Should not try and copy a file.") },
      createFolder: { _ in XCTFail("Should not check if the folder exists.") },
      data: { _ in
        XCTFail("Should not check file for data.")
        return Data()
      },
      folderExists: { _ in XCTFail("Should not check if the folder exists."); return false },
      fileExists: { _ in true },
      removeItem: { _ in XCTFail("Should not try and remove items.") })
    let migrator = ConfigurationMigrator(legacyUrl: url, fileManager: fileManager)

    XCTAssertFalse(try migrator.configurationNeedsMigration(at: url))
  }

  func testConfigurationMigrationWhereFileAlreadyExists() throws {
    let from = URL(fileURLWithPath: "~/.keyboard-cowboy.json").expandingTildeInPath
    let to = URL(fileURLWithPath: "~/.config/keyboardcowboy/config.json").expandingTildeInPath
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { _, _ in XCTFail("Should not try and copy a file.") },
      createFolder: { _ in XCTFail("Should not try and create a folder") },
      data: { _ in
        XCTFail("Should not check file for data.")
        return Data()
      },
      folderExists: { _ in XCTFail("Should not check if the folder exists."); return false },
      fileExists: { path in
        if path == from { return true }
        else if path == to { return true }
        return false
      },
      removeItem: { _ in XCTFail("Should not try and remove items.") })
    let migrator = ConfigurationMigrator(legacyUrl: from, fileManager: fileManager)

    do {
      try migrator.performMigration(from: from, to: to)
    } catch let error {
      switch error {
      case .migrationFileAlreadyExists(let resolvedUrl):
        XCTAssertEqual(to, resolvedUrl)
      default:
        XCTFail(error.localizedDescription)
      }
    }
  }

  func testConfigurationMigrationFailingOnCreatingFolder() throws {
    let from = URL(fileURLWithPath: "~/.keyboard-cowboy.json").expandingTildeInPath
    let to = URL(fileURLWithPath: "~/.config/keyboardcowboy/config.json").expandingTildeInPath
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { _, _ in XCTFail("Should not try and copy a file.") },
      createFolder: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
        throw ConfigurationMigratorError.unableToCreateDirectory(url)
      },
      data: { _ in
        XCTFail("Should not check file for data.")
        return Data()
      },
      folderExists: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
        return false
      },
      fileExists: { url in
        if url == from { return true }
        else if url == to { return false }
        return false
      },
      removeItem: { _ in XCTFail("Should not try and remove items.") })
    let migrator = ConfigurationMigrator(legacyUrl: from, fileManager: fileManager)

    do {
      try migrator.performMigration(from: from, to: to)
    } catch let error {
      switch error {
      case .unableToCreateDirectory(let resolvedUrl):
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent,
                       resolvedUrl.relativePath)
      default:
        XCTFail(error.localizedDescription)
      }
    }
  }

  func testConfigurationMigrationFailingOnCopy() throws {
    let from = URL(fileURLWithPath: "~/.keyboard-cowboy.json").expandingTildeInPath
    let to = URL(fileURLWithPath: "~/.config/keyboardcowboy/config.json").expandingTildeInPath
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { src, dest in
        throw ConfigurationMigratorError.unableToCopyFile(src, dest)
      },
      createFolder: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
      },
      data: { _ in
        XCTFail("Should not check file for data.")
        return Data()
      },
      folderExists: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
        return false
      }, fileExists: { url in
        if url == from { return true }
        else if url == to { return false }
        return false
      },
      removeItem: { _ in XCTFail("Should not try and remove items.") })
    let migrator = ConfigurationMigrator(legacyUrl: from, fileManager: fileManager)

    do {
      try migrator.performMigration(from: from, to: to)
    } catch let error {
      switch error {
      case .unableToCopyFile(let src, let dest):
        XCTAssertEqual(src, from)
        XCTAssertEqual(dest, to)
      default:
        XCTFail(error.localizedDescription)
      }
    }
  }

  func testConfigurationMigrationFailingDataCompare() throws {
    let from = URL(fileURLWithPath: "~/.keyboard-cowboy.json").expandingTildeInPath
    let to = URL(fileURLWithPath: "~/.config/keyboardcowboy/config.json").expandingTildeInPath
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { src, dest in
        XCTAssertEqual(from, src)
        XCTAssertEqual(dest, to)
        return
      },
      createFolder: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
      },
      data: { path in
        if path == from.relativePath {
          return from.relativePath.data(using: .utf8)!
        } else if path == to.relativePath {
          return to.relativePath.data(using: .utf8)!
        } else {
          XCTFail("Should never end up in this condition.")
          return Data()
        }
      },
      folderExists: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
        return false
      }, fileExists: { url in
        if url == from { return true }
        else if url == to { return false }
        return false
      },
      removeItem: { _ in XCTFail("Should not try and remove items.") })
    let migrator = ConfigurationMigrator(legacyUrl: from, fileManager: fileManager)

    do {
      try migrator.performMigration(from: from, to: to)
    } catch let error {
      switch error {
      case .comparingFileContentsFailed(let src, let dest):
        XCTAssertEqual(src, from)
        XCTAssertEqual(dest, to)
      default:
        XCTFail(error.localizedDescription)
      }
    }
  }

  func testConfigurationMigrationFailingRemoveItem() throws {
    let from = URL(fileURLWithPath: "~/.keyboard-cowboy.json").expandingTildeInPath
    let to = URL(fileURLWithPath: "~/.config/keyboardcowboy/config.json").expandingTildeInPath
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { src, dest in
        XCTAssertEqual(from, src)
        XCTAssertEqual(dest, to)
        return
      },
      createFolder: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
      },
      data: { path in
        return Data()
      },
      folderExists: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
        return false
      }, fileExists: { url in
        if url == from { return true }
        else if url == to { return false }
        return false
      },
      removeItem: { path in throw ConfigurationMigratorError.unableToRemoveItem(path) })
    let migrator = ConfigurationMigrator(legacyUrl: from, fileManager: fileManager)

    do {
      try migrator.performMigration(from: from, to: to)
    } catch let error {
      switch error {
      case .unableToRemoveItem(let path):
        XCTAssertEqual(path, from)
      default:
        XCTFail(error.localizedDescription)
      }
    }
  }

  func testConfigurationMigrationSuccess() throws {
    let from = URL(fileURLWithPath: "~/.keyboard-cowboy.json").expandingTildeInPath
    let to = URL(fileURLWithPath: "~/.config/keyboardcowboy/config.json").expandingTildeInPath
    let fileManager = ConfigurationFileManager(
      attributes: [:],
      copyItem: { src, dest in
        XCTAssertEqual(from, src)
        XCTAssertEqual(dest, to)
        return
      },
      createFolder: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
      },
      data: { path in
        return Data()
      },
      folderExists: { url in
        XCTAssertEqual((to.relativePath as NSString).deletingLastPathComponent, url.relativePath)
        return false
      }, fileExists: { url in
        if url == from { return true }
        else if url == to { return false }
        return false
      },
      removeItem: { path in
        XCTAssertEqual(path, from)
      })
    let migrator = ConfigurationMigrator(legacyUrl: from, fileManager: fileManager)

    XCTAssertNoThrow(try migrator.performMigration(from: from, to: to))
  }
}

private class ConfigurationFileManager: ConfigurationMigratorFileManager {

  let attributes: [FileAttributeKey : Any]
  let copyItem: (URL, URL) throws -> Void
  let createFolder: (URL) throws -> Void
  let data: (String) throws(ConfigurationMigratorError) -> Data
  let fileExists: (URL) -> Bool
  let folderExists: (URL) -> Bool
  let removeItem: (URL) throws -> Void

  init(attributes: [FileAttributeKey : Any], copyItem: @escaping (URL, URL) throws -> Void,
       createFolder: @escaping (URL) throws -> Void, data: @escaping (String) throws(ConfigurationMigratorError) -> Data,
       folderExists: @escaping (URL) -> Bool, fileExists: @escaping (URL) -> Bool,
       removeItem: @escaping (URL) throws -> Void) {
    self.attributes = attributes
    self.copyItem = copyItem
    self.createFolder = createFolder
    self.data = data
    self.folderExists = folderExists
    self.fileExists = fileExists
    self.removeItem = removeItem
  }

  func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] { attributes }

  func copyItem(at srcURL: URL, to dstURL: URL) throws {
    try copyItem(srcURL, dstURL)
  }

  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws {
    try createFolder(url)
  }

  func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
    folderExists(URL(filePath: path))
  }
  func fileExists(atPath path: String) -> Bool { fileExists(URL(fileURLWithPath: path)) }

  func dataFromContentsOfFile(atPath path: String) throws(Keyboard_Cowboy.ConfigurationMigratorError) -> Data {
      try data(path)
  }

  func removeItem(at URL: URL) throws { try removeItem(URL) }
}
