import Foundation

public extension Core {
  struct FileHandle {
    enum Mode {
      case production(Foundation.FileHandle)
      #if DEBUG
      case testing
      #endif
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
      #if DEBUG
      case .testing:
        Testing.mock.readToEnd
      #endif
      }
    }
  }
}
