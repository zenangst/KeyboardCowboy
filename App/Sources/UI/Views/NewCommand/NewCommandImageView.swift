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
        ModifierKeyIcon(key: .function)
      case .shortcut:
        image(for: "/System/Applications/Shortcuts.app")
      case .script:
        image(for: "/System/Applications/Utilities/Terminal.app")
      case .text:
        if let contents = FileManager.default.contents(atPath: "/System/Library/PrivateFrameworks/AOSUI.framework/Versions/A/Resources/pref_notes.icns"),
           let image = NSImage(data: contents) {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
        }
      case .system:
        image(for: "/System")
      case .menuBar:
        MenuIconView(size: 24, stacked: .constant(false))
      case .mouse:
        image(for: "/System/Library/Frameworks/IOBluetoothUI.framework/Versions/A/Resources/MightyMouse.icns")
      case .uiElement:
        UIElementIconView(size: 24, stacked: .constant(false))
      case .windowManagement:
        WindowManagementIconView(size: 24, stacked: .constant(false))
      case .builtIn:
        image(for: Bundle.main.bundlePath)
      }
    }
    .frame(width: 24, height: 24)
  }

  private func image(for path: String) -> some View {
    IconView(icon: .init(bundleIdentifier: path, path: path), size: .init(width: 24, height: 24))
  }
}

