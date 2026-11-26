public extension KeyboardTriggers {
  /// A single resolved shortcut. The caller uses the same keycode and flag
  /// normalization for bindings and input; matching never drops modifier bits.
  struct Signature: Hashable, Sendable {
    public let keyCode: UInt16
    public let flags: UInt64

    public init(keyCode: UInt16, flags: UInt64) {
      self.keyCode = keyCode
      self.flags = flags
    }

    /// Accepts value fields from input transport without altering the observed flags.
    public init?(eventKeyCode: Int64, flags: UInt64) {
      guard let code = UInt16(exactly: eventKeyCode) else { return nil }
      self.init(keyCode: code, flags: flags)
    }
  }
}
