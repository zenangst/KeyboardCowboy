import WindowTilingFeature

extension WindowTidy {
  private typealias Tile = WindowTiling.Action
  private static let quarters: [Tile] = [.topLeft, .bottomLeft, .topRight, .bottomRight]

  static func singleApp(_ windows: [Window], anchor: Window, layout: (Window) -> WindowTiling.Action?) -> [Plan.Step] {
    let left = favorsLeft(layout(anchor))
    switch windows.count {
    case 1: return [.init(window: anchor, action: .fill)]
    case 2: return [.init(window: anchor, action: left ? .arrangeLeftRight : .arrangeRightLeft)]
    case 3: return [.init(window: anchor, action: left ? .arrangeLeftQuarters : .arrangeRightQuarters)]
    default:
      return windows.reversed().map { window in
        if window.id == anchor.id { return .init(window: window, action: left ? .left : .right) }
        let action: Tile = switch (left, layout(window)) {
        case (_, .topLeft), (_, .topRight): left ? .topRight : .topLeft
        case (_, .bottomLeft), (_, .bottomRight): left ? .bottomRight : .bottomLeft
        case (_, .right): left ? .topRight : .topLeft
        case (_, .left): left ? .right : .left
        case (_, .top), (_, .bottom): left ? .bottom : .top
        case (_, .center): .center
        case (_, .fill): .fill
        default: left ? .bottomRight : .bottomLeft
        }
        return .init(window: window, action: action)
      }
    }
  }

  static func multipleApps(
    _ windows: [Window], anchor: Window, rules: [Rule], layout: (Window) -> WindowTiling.Action?,
  ) -> [Plan.Step] {
    let left = favorsLeft(layout(anchor))
    let order = Array(windows.reversed())
    if windows.count <= 3 {
      return order.enumerated().map { index, window in
        let action: Tile
        if window.id == anchor.id {
          action = left ? .left : .right
        } else if windows.count == 2 {
          action = left ? .right : .left
        } else if left {
          action = index == 0 ? .bottomRight : .topRight
        } else {
          action = index == 0 ? .bottomLeft : .topLeft
        }
        return .init(window: window, action: action)
      }
    }

    func rule(for window: Window) -> Tile? {
      guard let bundle = window.bundleIdentifier else { return nil }
      return rules.first { $0.bundleIdentifier == bundle }?.tiling
    }
    // Reserve explicit rule slots before allocating unruled windows.
    let reserved = Set(order.compactMap(rule).flatMap(slots))
    var occupied: Set<Tile> = []
    return order.compactMap { window in
      let explicit = rule(for: window)
      let preferred = explicit ?? layout(window)
      let blocked = explicit == nil ? occupied.union(reserved) : occupied
      let action: Tile?
      if let preferred, slots(preferred).allSatisfy({ !blocked.contains($0) }) {
        action = preferred
      } else {
        action = quarters.first { !occupied.contains($0) && !reserved.contains($0) }
      }
      guard let action else { return nil }
      occupied.formUnion(slots(action))
      return .init(window: window, action: action)
    }
  }

  private static func favorsLeft(_ layout: Tile?) -> Bool {
    switch layout {
    case .right, .topRight, .bottomRight, .bottom: false
    default: true
    }
  }

  private static func slots(_ action: Tile) -> [Tile] {
    switch action {
    case .left: [.topLeft, .bottomLeft]
    case .right: [.topRight, .bottomRight]
    case .top: [.topLeft, .topRight]
    case .bottom: [.bottomLeft, .bottomRight]
    case .fill: quarters
    default: [action]
    }
  }
}
