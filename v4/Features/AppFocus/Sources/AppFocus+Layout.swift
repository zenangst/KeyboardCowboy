import WindowTilingFeature

extension AppFocus {
  static func layout(
    _ action: WindowTiling.Action, windows: [Window], snapshot: Snapshot,
  ) -> WindowTiling.Action? {
    guard let first = windows.first else { return nil }
    let count = windows.count
    switch action {
    case .arrangeLeftRight, .arrangeRightLeft, .arrangeTopBottom, .arrangeBottomTop:
      return count <= 2 ? .fill : action
    case .arrangeRightQuarters where count == 2:
      return .arrangeRightQuarters
    case .arrangeDynamicQuarters:
      guard let display = snapshot.displays.first(where: { $0.intersects(first.frame) }) else { return .fill }
      let tile = WindowTiling.classify(first.frame, in: display, margin: snapshot.tilingMargin)
      let preferLeft = tile.map { [.left, .topLeft, .bottomLeft, .fill].contains($0) } ?? false
      return WindowTiling.resolvedAction(action, eligibleWindowCount: count, dynamicSide: preferLeft ? .left : .right)
    default:
      return WindowTiling.resolvedAction(action, eligibleWindowCount: count)
    }
  }
}
