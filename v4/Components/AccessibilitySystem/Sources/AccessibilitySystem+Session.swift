import ApplicationServices
import Dispatch
import Foundation

public extension AccessibilitySystem {
  /// Worker-confined. Never retain a session beyond its transaction closure.
  final class Session {
    private let transport: any Transport
    private let timeout: Float
    private let queue: DispatchQueue
    private let request: Request
    private let scope = UUID()
    private var active = true
    private var traversalDeadline: ContinuousClock.Instant?
    private var identities: [Handle: UUID] = [:]
    private var handles: [UUID: Handle] = [:]
    public let application: Element

    convenience init(pid: Int32, transport: any Transport, timeout: Float,
                     queue: DispatchQueue, request: Request) throws {
      try self.init(
        root: transport.application(pid),
        transport: transport,
        timeout: timeout,
        queue: queue,
        request: request)
    }

    init(root handle: Handle, transport: any Transport, timeout: Float,
         queue: DispatchQueue, request: Request) throws {
      self.transport = transport
      self.timeout = timeout
      self.queue = queue
      self.request = request
      let key = UUID()
      application = Element(key: key, scope: scope)
      try checkpoint()
      try transport.setTimeout(timeout, on: handle)
      try checkpoint()
      identities[handle] = key
      handles[key] = handle
    }

    func invalidate() {
      active = false
      identities.removeAll()
      handles.removeAll()
    }

    public func checkpoint() throws {
      dispatchPrecondition(condition: .onQueue(queue))
      guard active else { throw Failure(.expiredScope, operation: "session") }

      try request.check()
      if let traversalDeadline, ContinuousClock.now >= traversalDeadline {
        throw Failure(.traversalLimitReached, operation: "traversalDeadline")
      }
    }

    public func windows() throws -> [Element] {
      try checkpoint()
      return try elements(kAXWindowsAttribute, of: application)
    }

    #if DEBUG
    /// Diagnostic candidates only, not verified CG associations. A nil array
    /// means the bridge is unavailable; nil entries mean individual lookups failed.
    public func debugWindowIDCandidates() throws -> [CGWindowID?]? {
      try debugWindowIDCandidates(resolving: windows)
    }

    /// Returns unverified candidates in the supplied elements' order.
    public func debugWindowIDCandidates(for windows: [Element]) throws -> [CGWindowID?]? {
      try debugWindowIDCandidates(resolving: { windows })
    }

    private func debugWindowIDCandidates(resolving windows: () throws -> [Element]) throws -> [CGWindowID?]? {
      try checkpoint()
      return try DebugWindowID.withLookup { lookup in
        try windows().map { window in
          let id = try handle(for: window).native.flatMap(lookup)
          try checkpoint()
          return id
        }
      }
    }
    #endif

    public func children(of element: Element) throws -> [Element] {
      try elements(kAXChildrenAttribute, of: element)
    }

    public func focusedElement() throws -> Element {
      try checkpoint()
      return try element(transport.focusedElement())
    }

    public func focusedWindow() throws -> Element? {
      try relatedElement(kAXFocusedWindowAttribute, of: application)
    }

    public func menuBar() throws -> Element? {
      try relatedElement(kAXMenuBarAttribute, of: application)
    }

    public func parent(of element: Element) throws -> Element? {
      try relatedElement(kAXParentAttribute, of: element)
    }

    private func relatedElement(_ name: String, of source: Element) throws -> Element? {
      let handle = try handle(for: source)
      let value = try toleratingMissing(.skipNoValueOrUnsupported) { try transport.read(name, from: handle) }
      try checkpoint()
      guard let value else { return nil }
      guard case .element(let related) = value else {
        throw Failure(.malformedValue, operation: name)
      }
      return try element(related)
    }

    public func read<Value>(_ attribute: Attribute<Value>, of element: Element) throws -> Value {
      let handle = try handle(for: element)
      let value = try transport.read(attribute.name, from: handle)
      try checkpoint()
      return try attribute.decode(value)
    }

    func bounds(for range: NSRange, of element: Element) throws -> CGRect {
      let handle = try handle(for: element)
      let bounds = try transport.bounds(for: range, from: handle)
      try checkpoint()
      return bounds
    }

    public func perform(_ action: Action, on element: Element) throws {
      let handle = try handle(for: element)
      try transport.perform(action, on: handle)
      try checkpoint()
    }

    public func write(_ attribute: WritableAttribute<Bool>, value: Bool, to element: Element) throws {
      let handle = try handle(for: element)
      try transport.write(attribute.name, value: value, to: handle)
      try checkpoint()
    }

    public func write(_ attribute: WritableAttribute<String>, value: String, to element: Element) throws {
      let handle = try handle(for: element)
      try transport.write(attribute.name, value: value, to: handle)
      try checkpoint()
    }

    /// Depth-first pre-order, retaining source child order. Matched roles prune
    /// their descendants even when the requested value is missing (legacy policy).
    /// Missing role and leaf children may be skipped only under the skip policy.
    /// Budget exhaustion is an error, never a successful no-match result.
    public func firstValue<Value>(
      of attribute: Attribute<Value>, atRole role: Role, under root: Element,
      includingRoot: Bool, missingValue: MissingValuePolicy,
      budget: TraversalBudget = .init(),
    ) throws -> Value? {
      try traverse(under: root, includingRoot: includingRoot, missingValue: missingValue, budget: budget) { node, _ in
        let nodeRole = try toleratingMissing(missingValue) { try read(.role, of: node) }
        try checkpoint()
        guard nodeRole == role else { return .descend }
        if let value = try toleratingMissing(missingValue, { try read(attribute, of: node) }) {
          return .match(value)
        }
        return .prune
      }
    }

    /// Searches in depth-first pre-order. The caller owns matching and pruning
    /// policy; the session enforces the traversal budget and element lifetime.
    public func firstElement(
      under root: Element, includingRoot: Bool, missingChildren: MissingValuePolicy,
      budget: TraversalBudget = .init(),
      visit: (Element) throws -> SearchDecision,
    ) throws -> Element? {
      try traverse(under: root, includingRoot: includingRoot, missingValue: missingChildren, budget: budget) { node, _ in
        switch try visit(node) {
        case .match: .match(node)
        case .descend: .descend
        case .prune: .prune
        }
      }
    }

    public enum SearchDecision {
      case match, descend, prune
    }

    func firstElementWithReadableChildren(
      under root: Element, budget: TraversalBudget, matches: (Element) throws -> Bool,
    ) throws -> Element? {
      try traverse(under: root, includingRoot: true, missingValue: .fail, budget: budget,
                   readChildrenBeforeVisit: .skipUnreadable) { node, _ in
        try matches(node) ? .match(node) : .descend
      }
    }

    func firstLeaf(under root: Element, budget: TraversalBudget, matches: (Element) throws -> Bool) throws -> Element? {
      try traverse(under: root, includingRoot: true, missingValue: .fail, budget: budget,
                   readChildrenBeforeVisit: .fail) { node, isLeaf in
        try isLeaf && matches(node) ? .match(node) : .descend
      }
    }

    private enum EarlyChildRead {
      case skipUnreadable, fail
    }

    private enum Visit<Value> {
      case match(Value), descend, prune
    }

    private func traverse<Value>(
      under root: Element, includingRoot: Bool, missingValue: MissingValuePolicy,
      budget: TraversalBudget, readChildrenBeforeVisit: EarlyChildRead? = nil,
      visit: (Element, Bool) throws -> Visit<Value>,
    ) throws -> Value? {
      let rootHandle = try handle(for: root)
      guard budget.maximumNodes > 0, budget.maximumDepth >= 0, budget.elapsedLimit > .zero else {
        throw Failure(.invalidConfiguration, operation: "traversalBudget")
      }

      let clock = ContinuousClock()
      let deadline = clock.now.advanced(by: budget.elapsedLimit)
      let previousDeadline = traversalDeadline
      traversalDeadline = min(previousDeadline ?? deadline, deadline)
      defer { traversalDeadline = previousDeadline }
      var visited: Set<Handle> = []
      var stack: [(remaining: ArraySlice<Handle>, depth: Int)] = [([rootHandle][...], 0)]
      var count = 0

      func checkBudget() throws {
        try checkpoint()
        guard clock.now < deadline else {
          throw Failure(.traversalLimitReached, operation: "traversalDeadline")
        }
      }

      while let (siblings, depth) = stack.popLast() {
        try checkBudget()
        var remaining = siblings
        guard let handle = remaining.popFirst() else { continue }
        if !remaining.isEmpty { stack.append((remaining, depth)) }
        guard visited.insert(handle).inserted else { continue }

        count += 1
        guard count <= budget.maximumNodes, depth <= budget.maximumDepth else {
          throw Failure(.traversalLimitReached, operation: "traversal")
        }

        let node = try element(handle)
        let prefetched: [Handle]?
        if let readChildrenBeforeVisit {
          do {
            prefetched = try elementHandles(kAXChildrenAttribute, of: node)
          } catch let failure as Failure
            where readChildrenBeforeVisit == .skipUnreadable
              && failure.kind != .traversalLimitReached && failure.kind != .expiredScope {
            try checkBudget()
            continue
          }
        } else {
          prefetched = nil
        }
        if includingRoot || depth > 0 {
          let decision = try visit(node, prefetched?.isEmpty == true)
          try checkBudget()
          switch decision {
          case .match(let value): return value
          case .prune: continue
          case .descend: break
          }
        }
        let children = try prefetched ?? toleratingMissing(missingValue) { try elementHandles(kAXChildrenAttribute, of: node) } ?? []
        try checkBudget()
        if !children.isEmpty { stack.append((children[...], depth + 1)) }
      }
      return nil
    }

    private func toleratingMissing<T>(_ policy: MissingValuePolicy, _ operation: () throws -> T) throws -> T? {
      do {
        return try operation()
      } catch let failure as Failure {
        guard policy == .skipNoValueOrUnsupported,
              failure.kind == .noValue || failure.kind == .attributeUnsupported else { throw failure }

        return nil
      }
    }

    private func validate(_ element: Element) throws {
      try checkpoint()
      guard element.scope == scope else { throw Failure(.expiredScope, operation: "element") }
    }

    private func handle(for element: Element) throws -> Handle {
      try validate(element)
      guard let handle = handles[element.key] else {
        throw Failure(.expiredScope, operation: "element")
      }

      return handle
    }

    private func element(_ handle: Handle) throws -> Element {
      try checkpoint()

      if let key = identities[handle] {
        return Element(key: key, scope: scope)
      }

      try transport.setTimeout(timeout, on: handle)
      try checkpoint()
      let key = UUID()
      identities[handle] = key
      handles[key] = handle
      return Element(key: key, scope: scope)
    }

    private func elements(_ name: String, of parent: Element) throws -> [Element] {
      try elementHandles(name, of: parent).map { try element($0) }
    }

    private func elementHandles(_ name: String, of parent: Element) throws -> [Handle] {
      let handle = try handle(for: parent)
      let value = try transport.read(name, from: handle)

      try checkpoint()

      guard case .elements(let handles) = value else {
        throw Failure(.malformedValue, operation: name)
      }

      return handles
    }
  }
}
