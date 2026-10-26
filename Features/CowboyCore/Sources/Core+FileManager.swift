import Cocoa
import Foundation
import System

public extension Core {
  final class FileManager {
    private typealias Production = Foundation.FileManager

    private let env: Environment

    public init(_ env: Environment) {
      self.env = env
    }

    public func contents(atPath path: String) -> Data? {
      return switch env {
      case .production: Production.default.contents(atPath: path)
      #if DEBUG
      case .testing: Testing.mock.contentsAtPath
      #endif
      }
    }

    @discardableResult
    public func createFile(
      atPath path: String,
      contents data: Data?,
      attributes attr: [FileAttributeKey: Any]? = nil,
    ) -> Bool {
      switch env {
      case .production: Production.default.createFile(
          atPath: path,
          contents: data,
          attributes: attr,
        )
      #if DEBUG
      case .testing: Testing.mock.createFile
      #endif
      }
    }

    public func createTemporaryDirectory() throws -> URL {
      switch env {
      case .production:
        let url = URL(fileURLWithPath: try String(decoding: createTemporaryDirectoryPath()))
        try Production.default.createDirectory(
          at: url,
          withIntermediateDirectories: true,
        )
        return url
      #if DEBUG
      case .testing:
        return try Testing.mock.createDirectoryAtUrl()
      #endif
      }
    }

    public func fileExists(atPath path: String) -> Bool {
      switch env {
      case .production: Production.default.fileExists(atPath: path)
      #if DEBUG
      case .testing: Testing.mock.fileExistsAtPath
      #endif
      }
    }

    public func removeItem(atPath path: String) throws {
      switch env {
      case .production: try Production.default.removeItem(atPath: path)
      #if DEBUG
      case .testing: try Testing.mock.removeItem?()
      #endif
      }
    }

    // MARK: Private methods

    private func createTemporaryDirectoryPath() throws -> FilePath {
      var path = FilePath(Production.default.temporaryDirectory.path)

      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        path.append(bundleIdentifier)
      }

      path.append(UUID().uuidString)

      return path
    }
  }
}
