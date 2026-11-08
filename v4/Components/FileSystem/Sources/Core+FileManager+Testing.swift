import CowboyCore
#if DEBUG
import Foundation

extension Core.FileManager {
  public typealias ThrowingFunction = (@Sendable () throws -> Void)
  public typealias ThrowingURL = (@Sendable () throws -> URL)

  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var contentsAtPath: Data?
    var createDirectoryAtUrl: ThrowingURL
    var createFile: Bool
    var fileExistsAtPath: Bool
    var removeItem: ThrowingFunction?
    var createFileAtPath: (@Sendable (String, Data?) -> Bool)?
    var removeItemAtPath: (@Sendable (String) throws -> Void)?

    public init(
      contentsAtPath: Data? = nil,
      createDirectoryAtUrl: @escaping ThrowingURL = { URL(filePath: "/tmp") },
      createFile: Bool = false,
      fileExistsAtPath: Bool = false,
      removeItem: ThrowingFunction? = nil,
      createFileAtPath: (@Sendable (String, Data?) -> Bool)? = nil,
      removeItemAtPath: (@Sendable (String) throws -> Void)? = nil,
    ) {
      self.contentsAtPath = contentsAtPath
      self.createDirectoryAtUrl = createDirectoryAtUrl
      self.createFile = createFile
      self.fileExistsAtPath = fileExistsAtPath
      self.removeItem = removeItem
      self.createFileAtPath = createFileAtPath
      self.removeItemAtPath = removeItemAtPath
    }
  }
}
#endif
