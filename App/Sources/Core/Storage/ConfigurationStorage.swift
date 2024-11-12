import Apps
import Combine
import Foundation

enum ConfigurationStorageError: Error {
  case unableToFindFile
  case unableToCreateFile
  case unableToReadContents
  case unableToSaveContents(Error)
  case emptyFile
}

final class ConfigurationStorage: @unchecked Sendable {
  var configLocation: ConfigurationLocation

  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileManager: FileManager

  private var subscription: AnyCancellable?

  internal init(_ configLocation: ConfigurationLocation,
                decoder: JSONDecoder = .init(),
                encoder: JSONEncoder = .init(),
                fileManager: FileManager = .init()
  ) {
    self.configLocation = configLocation
    self.encoder = encoder
    self.decoder = decoder
    self.fileManager = fileManager
  }

  func subscribe(to publisher: Published<[KeyboardCowboyConfiguration]>.Publisher) {
    subscription = publisher
    // Skip the first empty state and the first time it gets loaded from disk.
      .dropFirst(1)
      .debounce(for: 0.5, scheduler: DispatchQueue.global(qos: .utility))
      .removeDuplicates()
      .sink { [weak self] configurations in
        try? self?.save(configurations)
      }
  }

  @MainActor
  func backupIfNeeded() {
    guard KeyboardCowboyApp.env() == .production else { return }

    let backupUrl = URL(fileURLWithPath: configLocation.path)
      .appending(path: "backups")

    let backupDestinationUrl = backupUrl.appending(path: "config.\(KeyboardCowboyApp.buildNumber).json")

    var isDirectory: ObjCBool = true
    if !fileManager.fileExists(atPath: backupUrl.path, isDirectory: &isDirectory) {
      try? fileManager.createDirectory(at: backupUrl, withIntermediateDirectories: true)
    }

    if !fileManager.fileExists(atPath: backupDestinationUrl.path()) {
      try? fileManager.copyItem(at: configLocation.url, to: backupDestinationUrl)
    }
  }

  func load() async throws -> [KeyboardCowboyConfiguration] {
    Benchmark.shared.start("Storage.load")

    if !fileManager.fileExists(atPath: configLocation.url.path) {
      let folderUrl = configLocation.url.deletingLastPathComponent()
      var isDirectory: ObjCBool = true
      if !fileManager.fileExists(atPath: folderUrl.path, isDirectory: &isDirectory) {
        try fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: true)
      }

      if !fileManager.createFile(atPath: configLocation.url.path, contents: nil) {
        Benchmark.shared.stop("Storage.load")
        throw ConfigurationStorageError.unableToFindFile
      }
    }

    guard let data = fileManager.contents(atPath: configLocation.url.path) else {
      Benchmark.shared.stop("Storage.load")
      throw ConfigurationStorageError.unableToReadContents
    }

    if data.count <= 1 {
      Benchmark.shared.stop("Storage.load")
      throw ConfigurationStorageError.emptyFile
    }

    do {
      let result = try decoder.decode([KeyboardCowboyConfiguration].self, from: data)

      if await Migration.shouldSave {
         try save(result)
      }
      Benchmark.shared.stop("Storage.load")
      return result
    } catch {
      do {
        let result = try await migrateIfNeeded()
        Benchmark.shared.stop("Storage.load")
        return result
      } catch {
        Benchmark.shared.stop("Storage.load")
        // TODO: Do something proper here.
        fatalError("Unable to load contents")
      }
    }
  }

  func load() async throws -> [WorkflowGroup] {
    guard let data = fileManager.contents(atPath: configLocation.url.path),
          !data.isEmpty else {
      throw ConfigurationStorageError.unableToReadContents
    }

    return try decoder.decode([WorkflowGroup].self, from: data)
  }

  func migrateIfNeeded() async throws -> [KeyboardCowboyConfiguration] {
    let groups: [WorkflowGroup] = try await load()
    let configuration = KeyboardCowboyConfiguration(
      name: "Default configuration",
      userModes: [],
      groups: groups
    )
    return [configuration]
  }

  func save(_ configurations: [KeyboardCowboyConfiguration]) throws {
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
      let data = try encoder.encode(configurations)
      fileManager.createFile(atPath: configLocation.url.path, contents: data, attributes: nil)
    } catch let error {
      throw ConfigurationStorageError.unableToSaveContents(error)
    }
  }
}
