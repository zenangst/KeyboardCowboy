#if DEBUG
import Foundation

public extension ProcessSystem.FileHandle {
  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  struct Mock: Sendable {
    var readToEnd: Data?

    public init(readToEnd: Data? = nil) {
      self.readToEnd = readToEnd
    }
  }
}
#endif
