import Foundation

@MainActor
final class WindowTilingCommandRunner {
  private let centerFocus: WindowFocusCenter
  private let relativeFocus: WindowFocusRelativeFocus
  private let quarterFocus: WindowFocusQuarter

  init(centerFocus: WindowFocusCenter, relativeFocus: WindowFocusRelativeFocus, quarterFocus: WindowFocusQuarter) {
    self.centerFocus = centerFocus
    self.relativeFocus = relativeFocus
    self.quarterFocus = quarterFocus
  }

  func resetFocusComponents() {
    centerFocus.reset()
    quarterFocus.reset()
    relativeFocus.reset()
  }

  func run(_ command: WindowTilingCommand, snapshot: UserSpace.Snapshot) async throws {
    switch command.kind {
    case .windowTilingLeft:
      try await WindowTilingRunner.run(.left, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingRight:
      try await WindowTilingRunner.run(.right, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingTop:
      try await WindowTilingRunner.run(.top, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingBottom:
      try await WindowTilingRunner.run(.bottom, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingTopLeft:
      try await WindowTilingRunner.run(.topLeft, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingTopRight:
      try await WindowTilingRunner.run(.topRight, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingBottomLeft:
      try await WindowTilingRunner.run(.bottomLeft, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingBottomRight:
      try await WindowTilingRunner.run(.bottomRight, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingCenter:
      try await WindowTilingRunner.run(.center, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingFill:
      try await WindowTilingRunner.run(.fill, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeLeftRight:
      try await WindowTilingRunner.run(.arrangeLeftRight, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeRightLeft:
      try await WindowTilingRunner.run(.arrangeRightLeft, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeTopBottom:
      try await WindowTilingRunner.run(.arrangeTopBottom, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeBottomTop:
      try await WindowTilingRunner.run(.arrangeBottomTop, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeLeftQuarters:
      try await WindowTilingRunner.run(.arrangeLeftQuarters, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeRightQuarters:
      try await WindowTilingRunner.run(.arrangeRightQuarters, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeTopQuarters:
      try await WindowTilingRunner.run(.arrangeTopQuarters, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeBottomQuarters:
      try await WindowTilingRunner.run(.arrangeBottomQuarters, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeDynamicQuarters:
      try await WindowTilingRunner.run(.arrangeDynamicQuarters, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingArrangeQuarters:
      try await WindowTilingRunner.run(.arrangeQuarters, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingPreviousSize:
      try await WindowTilingRunner.run(.previousSize, snapshot: snapshot)
      resetFocusComponents()
    case .windowTilingZoom:
      try await WindowTilingRunner.run(.zoom, snapshot: snapshot)
      resetFocusComponents()
    }
  }
}
