import SwiftUI

enum WindowFocusIconBuilder {
  @ViewBuilder @MainActor
  static func icon(_ kind: WindowFocusCommand.Kind?, size: CGFloat) -> some View {
    switch kind {
    case .accordianUp: EmptyView()
    case .accordianDown: EmptyView()
    case .accordianLeft: EmptyView()
    case .accordianRight: EmptyView()
    case .moveFocusToNextWindow:             MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size)
    case .moveFocusToNextWindowFront:        MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size)
    case .moveFocusToNextWindowGlobal:       MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
    case .moveFocusToPreviousWindow:         MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
    case .moveFocusToPreviousWindowFront:    MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size)
    case .moveFocusToPreviousWindowGlobal:   MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size)
    case .moveFocusToNextWindowCenter:       RelativeFocusIconView(.center, size: size)
    case .moveFocusToNextWindowUpwards:      RelativeFocusIconView(.up, size: size)
    case .moveFocusToNextWindowDownwards:    RelativeFocusIconView(.down, size: size)
    case .moveFocusToNextWindowOnLeft:       RelativeFocusIconView(.left, size: size)
    case .moveFocusToNextWindowOnRight:      RelativeFocusIconView(.right, size: size)
    case .moveFocusToNextWindowUpperLeftQuarter:      RelativeFocusIconView(.up, size: size)
    case .moveFocusToNextWindowLowerLeftQuarter:    RelativeFocusIconView(.down, size: size)
    case .moveFocusToNextWindowUpperRightQuarter:       RelativeFocusIconView(.left, size: size)
    case .moveFocusToNextWindowLowerRightQuarter:      RelativeFocusIconView(.right, size: size)
    case .none:                               EmptyView()
    }
  }
}
