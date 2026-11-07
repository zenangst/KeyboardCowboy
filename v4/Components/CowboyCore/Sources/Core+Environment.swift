public extension Core {
  enum Environment: Sendable {
    case production
    #if DEBUG
    case testing
    #endif
  }
}
