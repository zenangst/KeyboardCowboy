#if DEBUG
extension Core.NSAppleScript {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var compileAndReturnError: Bool = false
  }
}
#endif
