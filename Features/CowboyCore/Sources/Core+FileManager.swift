import Cocoa
import Foundation
import System

public extension Core {
  final class FileManager {
    public typealias ThrowingFunction = (@Sendable () throws -> Void)
    public typealias ThrowingURL = (@Sendable () throws -> URL)
    private typealias Production = Foundation.FileManager

    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var contentsAtPath: Data?
      var createDirectoryAtUrl: ThrowingURL
      var createFile: Bool = false
      var fileExistsAtPath: Bool = false
      var removeItem: ThrowingFunction?

      public init(
        contentsAtPath: Data? = nil,
        createDirectoryAtUrl: @escaping ThrowingURL = { URL(filePath: "/tmp") },
        createFile: Bool = false,
        removeItem: ThrowingFunction? = nil,
      ) {
        self.contentsAtPath = contentsAtPath
        self.createDirectoryAtUrl = createDirectoryAtUrl
        self.createFile = createFile
        self.removeItem = removeItem
      }
    }

    private let env: Environment

    public init(_ env: Environment) {
      self.env = env
    }

    public func contents(atPath path: String) -> Data? {
      return switch env {
      case .production: Production.default.contents(atPath: path)
      case .testing: Testing.mock.contentsAtPath
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
      case .testing: Testing.mock.createFile
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
      case .testing:
        return try Testing.mock.createDirectoryAtUrl()
      }
    }

    public func fileExists(atPath path: String) -> Bool {
      switch env {
      case .production: Production.default.fileExists(atPath: path)
      case .testing: Testing.mock.fileExistsAtPath
      }
    }

    public func removeItem(atPath path: String) throws {
      switch env {
      case .production: try Production.default.removeItem(atPath: path)
      case .testing: try Testing.mock.removeItem?()
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
