#if DEBUG
extension Core.ProcessInfo {
  public enum Testing {
    @TaskLocal public static var mock: [String: String] = [:]
  }
}
#endif
