import SwiftUI

struct CommandIconView: View {
  let command: Command

  var body: some View {
    switch command {
    case .application(let command):
      IconView(path: command.application.path)
        .frame(width: 32, height: 32)
        .id(command.application.id)
    case .script(let command):
      switch command {
      case .appleScript:
        IconView(path: "/System/Applications/Utilities/Script Editor.app")
          .frame(width: 32, height: 32)
      case .shell:
        IconView(path: "/System/Applications/Utilities/Terminal.app")
          .frame(width: 32, height: 32)
      }
    case .shortcut:
      IconView(path: "/System/Applications/Shortcuts.app")
        .frame(width: 32, height: 32)
    case .keyboard(let command):
      RegularKeyIcon(letter: command.keyboardShortcut.key, width: 32, height: 32)
        .frame(width: 24, height: 24)
    case .open(let command):
      if let application = command.application {
        IconView(path: application.path)
          .frame(width: 32, height: 32)
          .id(application.id)
      } else if command.isUrl {
        IconView(path: "/Applications/Safari.app")
          .frame(width: 32, height: 32)
      } else {
        IconView(path: command.path)
          .frame(width: 32, height: 32)
      }
      Spacer()
    case .builtIn:
      Spacer()
    case .type:
      FeatureIcon(color: .pink, size: CGSize(width: 32, height: 32), {
        TypingSymbol(foreground: Color.pink)
      }).redacted(reason: .placeholder)
    }

  }
}
