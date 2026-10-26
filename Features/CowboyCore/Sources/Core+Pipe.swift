import Foundation

public extension Core {
  final class Pipe {
    typealias Production = Foundation.Pipe

    enum Mode {
      case production(Production)
      #if DEBUG
      case testing(Core.FileHandle)
      #endif
    }

    let mode: Mode
    public let fileHandleForReading: Core.FileHandle

    public init(_ env: Environment) {
      switch env {
      case .production:
        let pipe = Production()
        self.mode = .production(pipe)
        self.fileHandleForReading = Core.FileHandle(.production(pipe.fileHandleForReading))
      #if DEBUG
      case .testing:
        let fileHandle = Core.FileHandle(.testing)
        self.mode = .testing(fileHandle)
        self.fileHandleForReading = fileHandle
      #endif
      }
    }
  }
}
