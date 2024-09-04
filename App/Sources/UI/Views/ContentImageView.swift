import Bonzai
import SwiftUI

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel
  let size: CGFloat
  @Binding var stacked: Bool

  @ViewBuilder
  var body: some View {
    switch image.kind {
    case .icon(let icon):
      IconView(icon: icon, size: .init(width: size, height: size))
    case .command(let kind):
      switch kind {
      case .application, .open:
        EmptyView()
      case .builtIn(let model):
        switch model.kind {
        case .macro(let action):
          switch action.kind {
          case .record:
            MacroIconView(.record, size: size - 6)
          case .remove:
            MacroIconView(.remove, size: size - 6)
          }
        case .userMode:
          UserModeIconView(size: size - 6)
        case .commandLine:
          CommandLineIconView(size: size - 6)
        }
      case .keyboard(let model):
        KeyboardIconView(model.keys.first?.key.uppercased() ?? "", size: size - 6)
          .opacity(model.keys.first != nil ? 1 : 0)
      case .script(let model):
        ContentScriptImageView(source: model.source, size: size)
      case .shortcut:
        ContentShortcutImageView(size: size)
      case .text:
        TypingIconView(size: size - 6)
      case .mouse:
        MouseIconView(size: size - 6)
      case .plain:
        EmptyView()
      case .systemCommand(let model):
        switch model.kind {
        case .activateLastApplication:
          ActivateLastApplicationIconView(size: size - 6)
        case .applicationWindows:
          MissionControlIconView(size: size - 6)
        case .minimizeAllOpenWindows:
          MinimizeAllIconView(size: size - 6)
        case .missionControl:
          MissionControlIconView(size: size - 6)
        case .moveFocusToNextWindow:
          MoveFocusToWindowIconView(direction: .next, scope: .visibleWindows, size: size - 6)
        case .moveFocusToNextWindowFront:
          MoveFocusToWindowIconView(direction: .next, scope: .activeApplication, size: size - 6)
        case .moveFocusToNextWindowGlobal:
          MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size - 6)
        case .moveFocusToPreviousWindow:
          MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size - 6)
        case .moveFocusToPreviousWindowFront:
          MoveFocusToWindowIconView(direction: .previous, scope: .activeApplication, size: size - 6)
        case .moveFocusToPreviousWindowGlobal:
          MoveFocusToWindowIconView(direction: .previous, scope: .allWindows, size: size - 6)
        case .moveFocusToNextWindowUpwards:
          RelativeFocusIconView(.up, size: size - 6)
        case .moveFocusToNextWindowDownwards:
          RelativeFocusIconView(.down, size: size - 6)
        case .moveFocusToNextWindowOnLeft:
          RelativeFocusIconView(.left, size: size - 6)
        case .moveFocusToNextWindowOnRight:
          RelativeFocusIconView(.right, size: size - 6)
        case .showDesktop:
          DockIconView(size: size - 6)
        case .windowTilingLeft:
          WindowTilingIcon(kind: .left, size: size - 6)
        case .windowTilingRight:
          WindowTilingIcon(kind: .right, size: size - 6)
        case .windowTilingTop:
          WindowTilingIcon(kind: .top, size: size - 6)
        case .windowTilingBottom:
          WindowTilingIcon(kind: .bottom, size: size - 6)
        case .windowTilingTopLeft:
          WindowTilingIcon(kind: .topLeft, size: size - 6)
        case .windowTilingTopRight:
          WindowTilingIcon(kind: .topRight, size: size - 6)
        case .windowTilingBottomLeft:
          WindowTilingIcon(kind: .bottomLeft, size: size - 6)
        case .windowTilingBottomRight:
          WindowTilingIcon(kind: .bottomRight, size: size - 6)
        case .windowTilingCenter:
          WindowTilingIcon(kind: .center, size: size - 6)
        case .windowTilingFill:
          WindowTilingIcon(kind: .fill, size: size - 6)
        case .windowTilingArrangeLeftRight:
          WindowTilingIcon(kind: .arrangeLeftRight, size: size - 6)
        case .windowTilingArrangeRightLeft:
          WindowTilingIcon(kind: .arrangeLeftRight, size: size - 6)
        case .windowTilingArrangeTopBottom:
          WindowTilingIcon(kind: .arrangeTopBottom, size: size - 6)
        case .windowTilingArrangeBottomTop:
          WindowTilingIcon(kind: .arrangeBottomTop, size: size - 6)
        case .windowTilingArrangeLeftQuarters:
          WindowTilingIcon(kind: .arrangeLeftQuarters, size: size - 6)
        case .windowTilingArrangeRightQuarters:
          WindowTilingIcon(kind: .arrangeRightQuarters, size: size - 6)
        case .windowTilingArrangeTopQuarters:
          WindowTilingIcon(kind: .arrangeTopQuarters, size: size - 6)
        case .windowTilingArrangeBottomQuarters:
          WindowTilingIcon(kind: .arrangeBottomQuarters, size: size - 6)
        case .windowTilingArrangeQuarters:
          WindowTilingIcon(kind: .arrangeQuarters, size: size - 6)
        case .windowTilingPreviousSize:
          WindowTilingIcon(kind: .previousSize, size: size - 6)
        case .windowTilingZoom:
          WindowTilingIcon(kind: .zoom, size: size - 6)
        }
      case .menuBar:
        MenuIconView(size: size - 6)
      case .windowManagement:
        WindowManagementIconView(size: size - 6)
      case .uiElement:
        UIElementIconView(size: size - 6)
      }
    }
  }
}
