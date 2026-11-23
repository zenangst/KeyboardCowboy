import Foundation

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

    public func children() throws -> [Child] {
      try Child(session: session, element: session.application).children()
    }

    public func checkpoint() throws {
      try session.checkpoint()
    }

    /// Returns text bounds in AX global screen coordinates, including for a caret.
    public func bounds(for range: NSRange) throws -> CGRect {
      try session.bounds(for: range, of: session.application)
    }

    /// Searches leaves in source order. A leaf must have a readable, empty child list.
    public func firstLeaf(budget: TraversalBudget = .init(), where matches: (Child) throws -> Bool) throws -> Child? {
      let match = try session.firstLeaf(under: session.application, budget: budget) {
        try matches(Child(session: session, element: $0))
      }
      return match.map { Child(session: session, element: $0) }
    }

    /// Searches the focused element and its descendants in source order.
    /// Nodes whose children cannot be read are skipped with their subtree.
    public func firstInSubtreeWithReadableChildren(
      budget: TraversalBudget = .init(), where matches: (Child) throws -> Bool,
    ) throws -> Child? {
      let match = try session.firstElementWithReadableChildren(under: session.application, budget: budget) {
        try matches(Child(session: session, element: $0))
      }
      return match.map { Child(session: session, element: $0) }
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

      public func children() throws -> [Child] {
        try session.children(of: element).map { Child(session: session, element: $0) }
      }
    }
  }
}
