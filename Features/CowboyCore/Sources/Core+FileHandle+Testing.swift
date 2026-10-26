#if DEBUG
import Foundation

extension Core.FileHandle {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var readToEnd: Data?
  }
}
#endif
