#if DEBUG
public extension ProcessSystem.ProcessInfo {
  enum Testing {
    @TaskLocal public static var mock: [String: String] = [:]
  }
}
#endif
