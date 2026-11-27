import CoreGraphics

public extension WindowFocus {
  /// Value state for the visible current-Space ring, not a Stage Manager or all-Spaces ring.
  struct SpaceRing: Sendable {
    public enum Direction: Sendable { case next, previous }

    private struct Identity: Hashable, Sendable {
      let id: CGWindowID
      let owner: pid_t

      init(_ window: Window) {
        id = window.id
        owner = window.owner
      }
    }

    private var windows: [Window] = []
    private var current: Identity?
    private var previous: Identity?
    private var pending: Identity?
    private var cursor = 0

    public init() {}

    /// Refresh before observing focus or selecting. Omit hidden and minimized windows.
    /// Existing entries retain their order; new entries go after the cursor in Y order.
    public mutating func update(_ inventory: [Window]) {
      let counts = Dictionary(grouping: inventory, by: \.id)
      let fresh = inventory.filter { $0.isEligible && counts[$0.id]?.count == 1 }
        .sorted { $0.frame.minY < $1.frame.minY }
      let indexed = Dictionary(uniqueKeysWithValues: fresh.map { (Identity($0), $0) })
      let cursorKey = windows.indices.contains(cursor) ? Identity(windows[cursor]) : nil
      var retained = windows.compactMap { indexed[Identity($0)] }
      let retainedKeys = Set(retained.map(Identity.init))
      let added = fresh.filter { !retainedKeys.contains(Identity($0)) }
      if let cursorKey, let index = retained.firstIndex(where: { Identity($0) == cursorKey }) {
        cursor = index
        retained.insert(contentsOf: added, at: index + 1)
      } else {
        retained.append(contentsOf: added)
        cursor = min(cursor, max(0, retained.count - 1))
      }
      windows = retained
      if let current, indexed[current] == nil { self.current = nil }
      if let previous, indexed[previous] == nil { self.previous = nil }
      if let pending, indexed[pending] == nil { self.pending = nil }
    }

    /// Observe exact AX focus. Confirmed selections move the cursor; other focus
    /// changes move the observed entry into the existing cursor slot.
    public mutating func observeFocus(windowID: CGWindowID, owner: pid_t) {
      guard let index = windows.firstIndex(where: { $0.id == windowID && $0.owner == owner }) else { return }
      let observed = Identity(windows[index])
      guard observed != current else { return }
      previous = current
      current = observed
      if pending == observed {
        cursor = index
      } else {
        let window = windows.remove(at: index)
        cursor = min(cursor, windows.count)
        windows.insert(window, at: cursor)
      }
      pending = nil
    }

    /// Selects without advancing observed focus. Previous prefers in-scope history.
    public mutating func select(_ direction: Direction, frontmostOwner: pid_t? = nil) -> Window? {
      pending = nil
      guard windows.count > 1 else { return nil }
      let active = current.flatMap { current in windows.firstIndex { Identity($0) == current } }
        ?? windows.firstIndex { $0.owner == frontmostOwner } ?? 0
      cursor = active
      let target: Window
      if direction == .previous, let previous, previous != Identity(windows[active]),
         let historical = windows.first(where: { Identity($0) == previous }) {
        target = historical
      } else {
        let step = direction == .next ? 1 : windows.count - 1
        target = windows[(active + step) % windows.count]
      }
      pending = Identity(target)
      return target
    }

    /// Call when the selected target cannot be focused.
    public mutating func cancelSelection() { pending = nil }

    /// Call when the active Space changes.
    public mutating func reset() { self = .init() }
  }
}
