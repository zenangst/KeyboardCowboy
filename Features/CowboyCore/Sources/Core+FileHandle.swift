import Foundation

public extension Core {
  struct FileHandle {
    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var readToEnd: Data?
    }

    enum Mode {
      case production(Foundation.FileHandle)
      case testing
    }

    private typealias Production = Foundation.FileHandle
    private let mode: Mode

    init(_ mode: Mode) {
      self.mode = mode
    }

    public func readToEnd() throws -> Data? {
      return switch mode {
      case .production(let fileHandle):
        try fileHandle.readToEnd()
      case .testing:
        Testing.mock.readToEnd
      }
    }
  }
}
