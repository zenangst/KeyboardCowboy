import Apps
import Combine
import Foundation

enum StorageError: Error {
  case unableToFindFile
  case unableToCreateFile
  case unableToReadContents
  case unableToSaveContents(Error)
  case emptyFile
}

final class Storage {
  var configuration: StorageConfiguration

  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileManager: FileManager

  private var subscription: AnyCancellable?

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

  func load() async throws -> [KeyboardCowboyConfiguration] {
    await Benchmark.shared.start("Storage.load")

    if !fileManager.fileExists(atPath: configuration.url.path) {
      if !fileManager.createFile(atPath: configuration.url.path, contents: nil) {
        await Benchmark.shared.finish("Storage.load")
        throw StorageError.unableToFindFile
      }
    }

    guard let data = fileManager.contents(atPath: configuration.url.path) else {
      await Benchmark.shared.finish("Storage.load")
      throw StorageError.unableToReadContents
    }

    if data.count <= 1 {
      await Benchmark.shared.finish("Storage.load")
      throw StorageError.emptyFile
    }

    do {
      let result = try decoder.decode([KeyboardCowboyConfiguration].self, from: data)

      if await Migration.shouldSave {
         try save(result)
      }
      await Benchmark.shared.finish("Storage.load")
      return result
    } catch {
      do {
        let result = try await migrateIfNeeded()
        await Benchmark.shared.finish("Storage.load")
        return result
      } catch {
        await Benchmark.shared.finish("Storage.load")
        // TODO: Do something proper here.
        fatalError("Unable to load contents")
      }
    }
  }

  func load() async throws -> [WorkflowGroup] {
    guard let data = fileManager.contents(atPath: configuration.url.path),
          !data.isEmpty else {
      throw StorageError.unableToReadContents
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
    encoder.outputFormatting = .prettyPrinted
    do {
      let data = try encoder.encode(configurations)
      fileManager.createFile(atPath: configuration.url.path, contents: data, attributes: nil)
    } catch let error {
      throw StorageError.unableToSaveContents(error)
    }
  }
}
