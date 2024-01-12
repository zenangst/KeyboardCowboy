import SwiftUI

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel
  let size: CGFloat

  @ViewBuilder
  var body: some View {
    switch image.kind {
    case .icon(let icon):
      ContentIconImageView(icon: icon, size: size)
    case .command(let kind):
      switch kind {
      case .menuBar, .application, .open, .builtIn:
        EmptyView()
      case .keyboard(let model):
        ContentKeyboardImageView(keys: model.keys)
          .rotationEffect(.degrees(-(3.75 * image.offset)))
          .offset(.init(width: -(image.offset * 1.25),
                        height: image.offset * 1.25))
      case .script(let model):
        ContentScriptImageView(source: model.source, size: size)
      case .shortcut:
        ContentShortcutImageView(size: size)
      case .text:
        ContentTypeImageView()
      case .plain, .systemCommand, .windowManagement, .mouse:
        EmptyView()
      case .uiElement:
        UIElementIconView(size: 22)
      }
    }
  }
}
