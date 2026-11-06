#if DEBUG
extension UserSpace {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    let frontmostApplication: Core.RunningApplication?

    init(frontmostApplication: Core.RunningApplication? = nil) {
      self.frontmostApplication = frontmostApplication
    }
  }
}
#endif
