#if DEBUG
import CowboyCore

extension Core.NSAppleEventDescriptor {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var stringValue: String?

    public init(stringValue: String? = nil) {
      self.stringValue = stringValue
    }
  }
}
#endif
