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
        case .showDesktop:
          DockIconView(size: size - 6)
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
