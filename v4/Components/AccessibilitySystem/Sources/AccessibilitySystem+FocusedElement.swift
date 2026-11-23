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

    /// Searches only direct children, in source order.
    public func firstChild(where matches: (Child) throws -> Bool) throws -> Child? {
      let match = try session.firstElement(under: session.application, includingRoot: false,
                                           missingChildren: .fail) { element in
        try matches(Child(session: session, element: element)) ? .match : .prune
      }
      return match.map { Child(session: session, element: $0) }
    }

    public struct Child {
      fileprivate let session: Session
      fileprivate let element: Element

      public func read<Value>(_ attribute: Attribute<Value>) throws -> Value {
        try session.read(attribute, of: element)
      }
    }
  }
}
