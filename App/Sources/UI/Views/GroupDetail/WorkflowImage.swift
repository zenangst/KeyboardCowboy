import Bonzai
import SwiftUI

struct WorkflowImage: View {
  let image: GroupDetailViewModel.ImageModel
  let size: CGFloat
  @Binding var stacked: Bool

  @ViewBuilder
  var body: some View {
    let iconSize: CGFloat = size - 6
    switch image.kind {
    case .application, .open: EmptyView()
    case .builtIn(let builtIn): BuiltinIconBuilder.icon(builtIn, size: iconSize)
    case .bundled(let bundled): switch bundled {
      case .appFocus: AppFocusIcon(size: iconSize)
      case .workspace: WorkspaceIcon(size: iconSize)
      case .tidy: WindowTidyIcon(size: iconSize)
      }
    case .keyboard(let string): KeyboardIconView(string, size: iconSize)
    case .script(let source): ContentScriptImageView(source: source, size: iconSize)
    case .plain: EmptyView()
    case .shortcut: WorkflowShortcutImage(size: iconSize)
    case .text: TypingIconView(size: iconSize)
    case .systemCommand(let kind): SystemIconBuilder.icon(kind, size: iconSize)
    case .menuBar: MenuIconView(size: iconSize)
    case .mouse: MouseIconView(size: iconSize)
    case .uiElement: UIElementIconView(size: iconSize)
    case .windowFocus(let kind): WindowFocusIconBuilder.icon(kind, size: iconSize)
    case .windowManagement: WindowManagementIconView(size: iconSize)
    case .windowTiling(let kind): WindowTilingIconBuilder.icon(kind, size: iconSize)
    case .icon(let icon): IconView(icon: icon, size: .init(width: size, height: size))
    }
  }
}
