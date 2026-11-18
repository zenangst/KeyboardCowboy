import ApplicationSystem

#if DEBUG
public extension UserSpace {
  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  struct Mock: Sendable {
    let frontmostApplication: ApplicationSystem.RunningApplication?

    init(frontmostApplication: ApplicationSystem.RunningApplication? = nil) {
      self.frontmostApplication = frontmostApplication
    }
  }
}
#endif
