public enum RuntimeEnvironment {
  public enum Mode: Sendable {
    case production
    #if DEBUG
    case testing
    #endif
  }
}
