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
      return try elements("AXWindows", of: application)
    }

    public func children(of element: Element) throws -> [Element] {
      try elements("AXChildren", of: element)
    }

    public func read<Value>(_ attribute: Attribute<Value>, of element: Element) throws -> Value {
      let handle = try handle(for: element)
      let value = try transport.read(attribute.name, from: handle)
      try checkpoint()
      return try attribute.decode(value)
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
      of attribute: Attribute<Value>, atRole role: String, under root: Element,
      includingRoot: Bool, missingValue: MissingValuePolicy,
      budget: TraversalBudget = .init(),
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

      func toleratingMissing<T>(_ operation: () throws -> T) throws -> T? {
        do {
          return try operation()
        } catch let failure as Failure {
          guard missingValue == .skipNoValueOrUnsupported,
                failure.kind == .noValue || failure.kind == .attributeUnsupported else { throw failure }

          return nil
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
        if includingRoot || depth > 0 {
          let nodeRole = try toleratingMissing { try read(.role, of: node) }
          try checkBudget()
          if nodeRole == role {
            let value = try toleratingMissing { try read(attribute, of: node) }
            try checkBudget()
            if let value { return value }
            continue
          }
        }
        let children = try toleratingMissing { try elementHandles("AXChildren", of: node) } ?? []
        try checkBudget()
        if !children.isEmpty { stack.append((children[...], depth + 1)) }
      }
      return nil
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
