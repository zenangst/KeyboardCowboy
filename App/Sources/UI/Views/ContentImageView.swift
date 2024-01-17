import SwiftUI

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel
  let size: CGFloat
  @Binding var stacked: Bool

  @ViewBuilder
  var body: some View {
    switch image.kind {
    case .icon(let icon):
      ContentIconImageView(icon: icon, size: size)
    case .command(let kind):
      switch kind {
      case .application, .open, .builtIn:
        EmptyView()
      case .keyboard(let model):
        if let firstKey = model.keys.first {
          KeyboardIconView(firstKey.key.uppercased(), size: size - 6)
        }
      case .script(let model):
        ContentScriptImageView(source: model.source, size: size)
      case .shortcut:
        ContentShortcutImageView(size: size)
      case .text:
        TypingIconView(size: size - 6)
      case .plain, .systemCommand, .mouse:
        EmptyView()
      case .menuBar:
        MenuIconView(size: size - 6, stacked: $stacked)
      case .windowManagement:
        WindowManagementIconView(size: size - 6, stacked: $stacked)
      case .uiElement:
        UIElementIconView(size: size - 6, stacked: $stacked)
      }
    }
  }
}
