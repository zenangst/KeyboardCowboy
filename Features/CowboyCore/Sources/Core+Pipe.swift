import Foundation

public extension Core {
  final class Pipe {
    typealias Production = Foundation.Pipe

    enum Mode {
      case production(Production)
      case testing(Core.FileHandle)
    }

    let mode: Mode
    public let fileHandleForReading: Core.FileHandle

    public init(_ env: Environment) {
      switch env {
      case .production:
        let pipe = Production()
        self.mode = .production(pipe)
        self.fileHandleForReading = Core.FileHandle(.production(pipe.fileHandleForReading))
      case .testing:
        let fileHandle = Core.FileHandle(.testing)
        self.mode = .testing(fileHandle)
        self.fileHandleForReading = fileHandle
      }
    }
  }
}
