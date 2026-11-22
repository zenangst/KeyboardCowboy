public extension AccessibilitySystem {
  struct FocusedElement {
    fileprivate let session: Session

    init(in session: Session) {
      self.session = session
    }

    public func read<Value>(_ attribute: Attribute<Value>) throws -> Value {
      try session.read(attribute, of: session.application)
    }

    public func write(_ attribute: WritableAttribute<String>, value: String) throws {
      try session.write(attribute, value: value, to: session.application)
    }
  }
}
