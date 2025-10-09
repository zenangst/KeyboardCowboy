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
    case let .builtIn(builtIn): BuiltinIconBuilder.icon(builtIn, size: iconSize)
    case let .bundled(bundled): switch bundled {
      case .activatePreviousWorkspace: WorkspaceIcon(.activatePrevious, size: iconSize)
      case .appFocus: AppFocusIcon(size: iconSize)
      case .tidy: WindowTidyIcon(size: iconSize)
      case .workspace: WorkspaceIcon(.regular, size: iconSize)
      }
    case .inputSource: InputSourceIcon(size: iconSize)
    case let .keyboard(string): KeyboardIconView(string, size: iconSize)
    case let .script(source): ContentScriptImageView(source: source, size: iconSize)
    case .plain: EmptyView()
    case .shortcut: WorkflowShortcutImage(size: iconSize)
    case .text: TypingIconView(size: iconSize)
    case let .systemCommand(kind): SystemIconBuilder.icon(kind, size: iconSize)
    case .menuBar: MenuIconView(size: iconSize)
    case .mouse: MouseIconView(size: iconSize)
    case .uiElement: UIElementIconView(size: iconSize)
    case let .windowFocus(kind): WindowFocusIconBuilder.icon(kind, size: iconSize)
    case .windowManagement: WindowManagementIconView(size: iconSize)
    case let .windowTiling(kind): WindowTilingIconBuilder.icon(kind, size: iconSize)
    case let .icon(icon): IconView(icon: icon, size: .init(width: size, height: size))
    }
  }
}
