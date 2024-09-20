import SwiftUI

enum SystemIconBuilder {
  @ViewBuilder @MainActor
  static func icon(_ kind: SystemCommand.Kind?, size: CGFloat) -> some View {
    switch kind {
    case .activateLastApplication:           ActivateLastApplicationIconView(size: size)
    case .applicationWindows:                MissionControlIconView(size: size)
    case .minimizeAllOpenWindows:            MinimizeAllIconView(size: size)
    case .hideAllApps:                       HideAllIconView(size: size)
    case .missionControl:                    MissionControlIconView(size: size)
    case .moveFocusToNextWindow:             MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
    case .moveFocusToNextWindowFront:        MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
    case .moveFocusToNextWindowGlobal:       MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
    case .moveFocusToPreviousWindow:         MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
    case .moveFocusToPreviousWindowFront:    MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
    case .moveFocusToPreviousWindowGlobal:   MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
    case .moveFocusToNextWindowCenter:       RelativeFocusIconView(.center, size: size)
    case .showDesktop:                       DockIconView(size: size)
    case .moveFocusToNextWindowUpwards:      RelativeFocusIconView(.up, size: size)
    case .moveFocusToNextWindowDownwards:    RelativeFocusIconView(.down, size: size)
    case .moveFocusToNextWindowOnLeft:       RelativeFocusIconView(.left, size: size)
    case .moveFocusToNextWindowOnRight:      RelativeFocusIconView(.right, size: size)

    case .moveFocusToNextWindowUpperLeftQuarter:      RelativeFocusIconView(.up, size: size)
    case .moveFocusToNextWindowLowerLeftQuarter:    RelativeFocusIconView(.down, size: size)
    case .moveFocusToNextWindowUpperRightQuarter:       RelativeFocusIconView(.left, size: size)
    case .moveFocusToNextWindowLowerRightQuarter:      RelativeFocusIconView(.right, size: size)

    case .windowTilingLeft:                  WindowTilingIcon(kind: .left, size: size)
    case .windowTilingRight:                 WindowTilingIcon(kind: .right, size: size)
    case .windowTilingTop:                   WindowTilingIcon(kind: .top, size: size)
    case .windowTilingBottom:                WindowTilingIcon(kind: .bottom, size: size)
    case .windowTilingTopLeft:               WindowTilingIcon(kind: .topLeft, size: size)
    case .windowTilingTopRight:              WindowTilingIcon(kind: .topRight, size: size)
    case .windowTilingBottomLeft:            WindowTilingIcon(kind: .bottomLeft, size: size)
    case .windowTilingBottomRight:           WindowTilingIcon(kind: .bottomRight, size: size)
    case .windowTilingCenter:                WindowTilingIcon(kind: .center, size: size)
    case .windowTilingFill:                  WindowTilingIcon(kind: .fill, size: size)
    case .windowTilingArrangeLeftRight:      WindowTilingIcon(kind: .arrangeLeftRight, size: size)
    case .windowTilingArrangeRightLeft:      WindowTilingIcon(kind: .arrangeRightLeft, size: size)
    case .windowTilingArrangeTopBottom:      WindowTilingIcon(kind: .arrangeTopBottom, size: size)
    case .windowTilingArrangeBottomTop:      WindowTilingIcon(kind: .arrangeBottomTop, size: size)
    case .windowTilingArrangeLeftQuarters:   WindowTilingIcon(kind: .arrangeLeftQuarters, size: size)
    case .windowTilingArrangeRightQuarters:  WindowTilingIcon(kind: .arrangeRightQuarters, size: size)
    case .windowTilingArrangeTopQuarters:    WindowTilingIcon(kind: .arrangeTopQuarters, size: size)
    case .windowTilingArrangeBottomQuarters: WindowTilingIcon(kind: .arrangeBottomQuarters, size: size)
    case .windowTilingArrangeQuarters:       WindowTilingIcon(kind: .arrangeQuarters, size: size)
    case .windowTilingPreviousSize:          WindowTilingIcon(kind: .previousSize, size: size)
    case .windowTilingZoom:                  WindowTilingIcon(kind: .zoom, size: size)
    case .none:                              EmptyView()
    }
  }
}
