import AccessibilitySystem
import Darwin

public extension WindowTiling {
  /// Picks an enabled native tiling item in the supplied application's menu.
  /// The caller owns activation and window selection. Returns false for an
  /// unavailable menu/action; true means AX accepted the pick, not that the
  /// native layout settled. No geometry fallback or fill history is applied.
  @discardableResult
  static func execute(
    _ action: Action, in processIdentifier: pid_t, using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> Bool {
    guard processIdentifier > 0, processIdentifier != getpid() else { return false }
    return try await accessibility.withApplication(processIdentifier: processIdentifier) { session in
      guard let root = try session.menuBar() else { return false }
      return try execute(
        action, root: root,
        children: { node in try optional { try session.children(of: node) } ?? [] },
        identifier: { node in try optional { try session.read(.identifier, of: node) } },
        enabled: { node in try optional { try session.read(.enabled, of: node) } ?? false },
        pick: { try session.perform(.pick, on: $0) },
      )
    }
  }

  static func execute<Node>(
    _ action: Action, root: Node, children: (Node) throws -> [Node],
    identifier: (Node) throws -> String?, enabled: (Node) throws -> Bool,
    pick: (Node) throws -> Void,
  ) throws -> Bool {
    func matching(_ action: Action, in items: [Node]) throws -> Node? {
      try items.first { try identifier($0) == action.menuIdentifier && enabled($0) }
    }

    func menuItems(in item: Node) throws -> [Node] {
      guard let menu = try children(item).first else { return [] }
      return try children(menu)
    }

    for item in try children(root).reversed() {
      let windowItems = try menuItems(in: item)
      guard try matching(.center, in: windowItems) != nil else { continue }
      let target: Node?
      if action.isDirectWindowMenuAction {
        target = try matching(action, in: windowItems)
      } else {
        var resizeItems: [Node] = []
        for item in windowItems {
          let items = try menuItems(in: item)
          if try matching(.left, in: items) != nil {
            resizeItems = items
            break
          }
        }
        target = try matching(action, in: resizeItems)
      }
      guard let target else { return false }
      try Task.checkCancellation()
      try pick(target)
      return true
    }
    return false
  }

  private static func optional<Value>(_ read: () throws -> Value) throws -> Value? {
    do {
      return try read()
    } catch let failure as AccessibilitySystem.Failure
      where failure.kind == .noValue || failure.kind == .attributeUnsupported {
      return nil
    }
  }
}
