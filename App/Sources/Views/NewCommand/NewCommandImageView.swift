import SwiftUI

struct NewCommandImageView: View {
  let kind: NewCommandView.Kind

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
      case .type:
        if let contents = FileManager.default.contents(atPath: "/System/Library/PrivateFrameworks/AOSUI.framework/Versions/A/Resources/pref_notes.icns"),
           let image = NSImage(data: contents) {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
        }
      }
    }
    .frame(width: 24, height: 24)
  }

  private func image(for path: String) -> some View {
    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
      .resizable()
      .aspectRatio(1, contentMode: .fill)
  }
}

