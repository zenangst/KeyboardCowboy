import SwiftUI

enum WindowTilingIconBuilder {
  @ViewBuilder @MainActor
  static func icon(_ kind: WindowTiling?, size: CGFloat) -> some View {
    switch kind {
    case .left:                   WindowTilingIcon(kind: .left, size: size)
    case .right:                  WindowTilingIcon(kind: .right, size: size)
    case .top:                    WindowTilingIcon(kind: .top, size: size)
    case .bottom:                 WindowTilingIcon(kind: .bottom, size: size)
    case .topLeft:                WindowTilingIcon(kind: .topLeft, size: size)
    case .topRight:               WindowTilingIcon(kind: .topRight, size: size)
    case .bottomLeft:             WindowTilingIcon(kind: .bottomLeft, size: size)
    case .bottomRight:            WindowTilingIcon(kind: .bottomRight, size: size)
    case .center:                 WindowTilingIcon(kind: .center, size: size)
    case .fill:                   WindowTilingIcon(kind: .fill, size: size)
    case .zoom:                   WindowTilingIcon(kind: .arrangeLeftRight, size: size)
    case .arrangeLeftRight:       WindowTilingIcon(kind: .arrangeRightLeft, size: size)
    case .arrangeRightLeft:       WindowTilingIcon(kind: .arrangeTopBottom, size: size)
    case .arrangeTopBottom:       WindowTilingIcon(kind: .arrangeBottomTop, size: size)
    case .arrangeBottomTop:       WindowTilingIcon(kind: .arrangeLeftQuarters, size: size)
    case .arrangeLeftQuarters:    WindowTilingIcon(kind: .arrangeRightQuarters, size: size)
    case .arrangeRightQuarters:   WindowTilingIcon(kind: .arrangeTopQuarters, size: size)
    case .arrangeTopQuarters:     WindowTilingIcon(kind: .arrangeBottomQuarters, size: size)
    case .arrangeBottomQuarters:  WindowTilingIcon(kind: .arrangeDynamicQuarters, size: size)
    case .arrangeDynamicQuarters: WindowTilingIcon(kind: .arrangeQuarters, size: size)
    case .arrangeQuarters:        WindowTilingIcon(kind: .previousSize, size: size)
    case .previousSize:           WindowTilingIcon(kind: .zoom, size: size)
    case .none:                   EmptyView()
    }
  }
}
