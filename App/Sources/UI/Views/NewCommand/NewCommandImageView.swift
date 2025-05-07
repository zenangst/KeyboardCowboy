import Bonzai
import SwiftUI

struct NewCommandImageView: View {
  let kind: NewCommandView.Kind

  @ViewBuilder
  var body: some View {
    Group {
      switch kind {
      case .open:
        ZStack {
          image(for: "~/")
            .rotationEffect(.degrees(5))
            .offset(.init(width: 4, height: -2))
          image(for: "~/".sanitizedPath)
        }
      case .url:
        image(for: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app")
      case .application:
        image(for: "/Applications")
      case .keyboardShortcut:
        KeyboardIconView("fn", size: 24)
      case .shortcut:
        image(for: "/System/Applications/Shortcuts.app")
      case .script:
        ScriptIconView(size: 24)
      case .text:
        TypingIconView(size: 24)
      case .system:
        image(for: "/System")
      case .menuBar:
        MenuIconView(size: 24)
      case .mouse:
        MouseIconView(size: 24)
      case .uiElement:
        UIElementIconView(size: 24)
      case .windowManagement:
        WindowManagementIconView(size: 24)
      case .builtIn:
        image(for: Bundle.main.bundlePath)
      case .bundled:
        WorkspaceIcon(.regular, size: 24)
      }
    }
    .frame(width: 24, height: 24)
  }

  private func image(for path: String) -> some View {
    IconView(icon: .init(bundleIdentifier: path, path: path), size: .init(width: 24, height: 24))
  }
}

