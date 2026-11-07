#if DEBUG
extension Core.NSAppleEventDescriptor {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var stringValue: String?
  }
}
#endif
