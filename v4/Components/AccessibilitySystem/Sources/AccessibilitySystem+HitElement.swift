public extension AccessibilitySystem {
  struct HitElement {
    fileprivate let session: Session

    init(in session: Session) {
      self.session = session
    }

    public func read<Value>(_ attribute: Attribute<Value>) throws -> Value {
      try session.read(attribute, of: session.application)
    }
  }
}
