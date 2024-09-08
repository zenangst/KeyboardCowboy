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
        BuiltinIconBuilder.icon(model.kind, size: size - 6)
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
        SystemIconBuilder.icon(model.kind, size: size - 6)
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
