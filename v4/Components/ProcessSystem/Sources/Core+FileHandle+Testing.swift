import CowboyCore
#if DEBUG
import Foundation

extension Core.FileHandle {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var readToEnd: Data?

    public init(readToEnd: Data? = nil) {
      self.readToEnd = readToEnd
    }
  }
}
#endif
