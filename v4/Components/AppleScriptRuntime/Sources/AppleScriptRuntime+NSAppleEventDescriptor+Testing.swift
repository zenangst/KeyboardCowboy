#if DEBUG

public extension AppleScriptRuntime.NSAppleEventDescriptor {
  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  struct Mock: Sendable {
    var stringValue: String?

    public init(stringValue: String? = nil) {
      self.stringValue = stringValue
    }
  }
}
#endif
