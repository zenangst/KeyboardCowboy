import Foundation
import RuntimeEnvironment

public extension ProcessSystem {
  final class Pipe {
    typealias Production = Foundation.Pipe

    enum Mode {
      case production(Production)
      #if DEBUG
      case testing(ProcessSystem.FileHandle)
      #endif
    }

    let mode: Mode
    public let fileHandleForReading: ProcessSystem.FileHandle

    var readingDescriptor: Int32? {
      if case .production(let pipe) = mode { return pipe.fileHandleForReading.fileDescriptor }
      return nil
    }

    func closeReading() {
      if case .production(let pipe) = mode { try? pipe.fileHandleForReading.close() }
    }

    public init(_ env: RuntimeEnvironment.Mode) {
      switch env {
      case .production:
        let pipe = Production()
        self.mode = .production(pipe)
        self.fileHandleForReading = ProcessSystem.FileHandle(.production(pipe.fileHandleForReading))
      #if DEBUG
      case .testing:
        let fileHandle = ProcessSystem.FileHandle(.testing)
        self.mode = .testing(fileHandle)
        self.fileHandleForReading = fileHandle
      #endif
      }
    }
  }
}
