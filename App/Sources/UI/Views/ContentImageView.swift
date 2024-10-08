import Bonzai
import SwiftUI

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel
  let size: CGFloat
  @Binding var stacked: Bool

  @ViewBuilder
  var body: some View {
    let iconSize: CGFloat = size - 6
    switch image.kind {
    case .application, .open:
      EmptyView()
    case .builtIn(let builtIn):
      BuiltinIconBuilder.icon(builtIn, size: iconSize)
    case .bundled(let bundled):
      switch bundled {
      case .focusOnApp:
        FocusOnAppIcon(size: iconSize)
      case .workspace:
        WorkspaceIcon(size: iconSize)
      }
    case .keyboard(let string):
      KeyboardIconView(string, size: iconSize)
    case .script(let source):
      ContentScriptImageView(source: source, size: iconSize)
    case .plain:
      EmptyView()
    case .shortcut:
      ContentShortcutImageView(size: iconSize)
    case .text(let text):
      TypingIconView(size: iconSize)
    case .systemCommand(let kind):
      SystemIconBuilder.icon(kind, size: iconSize)
    case .menuBar:
      MenuIconView(size: iconSize)
    case .mouse:
      MouseIconView(size: iconSize)
    case .uiElement:
      UIElementIconView(size: iconSize)
    case .windowManagement:
      WindowManagementIconView(size: iconSize)
    case .icon(let icon):
      IconView(icon: icon, size: .init(width: size, height: size))
    }
  }
}
