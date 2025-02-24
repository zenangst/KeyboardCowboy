import SwiftUI

enum WindowTilingIconBuilder {
  @ViewBuilder @MainActor
  static func icon(_ kind: WindowTilingCommand.Kind?, size: CGFloat) -> some View {
    switch kind {
    case .windowTilingLeft:                   WindowTilingIcon(kind: .left, size: size)
    case .windowTilingRight:                  WindowTilingIcon(kind: .right, size: size)
    case .windowTilingTop:                    WindowTilingIcon(kind: .top, size: size)
    case .windowTilingBottom:                 WindowTilingIcon(kind: .bottom, size: size)
    case .windowTilingTopLeft:                WindowTilingIcon(kind: .topLeft, size: size)
    case .windowTilingTopRight:               WindowTilingIcon(kind: .topRight, size: size)
    case .windowTilingBottomLeft:             WindowTilingIcon(kind: .bottomLeft, size: size)
    case .windowTilingBottomRight:            WindowTilingIcon(kind: .bottomRight, size: size)
    case .windowTilingCenter:                 WindowTilingIcon(kind: .center, size: size)
    case .windowTilingFill:                   WindowTilingIcon(kind: .fill, size: size)
    case .windowTilingArrangeLeftRight:       WindowTilingIcon(kind: .arrangeLeftRight, size: size)
    case .windowTilingArrangeRightLeft:       WindowTilingIcon(kind: .arrangeRightLeft, size: size)
    case .windowTilingArrangeTopBottom:       WindowTilingIcon(kind: .arrangeTopBottom, size: size)
    case .windowTilingArrangeBottomTop:       WindowTilingIcon(kind: .arrangeBottomTop, size: size)
    case .windowTilingArrangeLeftQuarters:    WindowTilingIcon(kind: .arrangeLeftQuarters, size: size)
    case .windowTilingArrangeRightQuarters:   WindowTilingIcon(kind: .arrangeRightQuarters, size: size)
    case .windowTilingArrangeTopQuarters:     WindowTilingIcon(kind: .arrangeTopQuarters, size: size)
    case .windowTilingArrangeBottomQuarters:  WindowTilingIcon(kind: .arrangeBottomQuarters, size: size)
    case .windowTilingArrangeDynamicQuarters: WindowTilingIcon(kind: .arrangeDynamicQuarters, size: size)
    case .windowTilingArrangeQuarters:        WindowTilingIcon(kind: .arrangeQuarters, size: size)
    case .windowTilingPreviousSize:           WindowTilingIcon(kind: .previousSize, size: size)
    case .windowTilingZoom:                   WindowTilingIcon(kind: .zoom, size: size)
    case .none:                               EmptyView()
    }
  }
}
