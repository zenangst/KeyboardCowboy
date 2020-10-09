import SwiftUI

struct ShellScriptView: View {
  let command: CommandViewModel
  let editAction: (CommandViewModel) -> Void
  let revealAction: (CommandViewModel) -> Void
  let runAction: (CommandViewModel) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      ZStack {
        IconView(identifier: "shell-script-file", path: "/System/Applications/Utilities/Terminal.app")
          .frame(width: 32, height: 32)
        PlayArrowView()
      }
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name).lineLimit(1)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button("Edit", action: { editAction(command) })
              .foregroundColor(Color(.controlAccentColor))
            Text("|").foregroundColor(Color(.secondaryLabelColor))
            Button("Reveal", action: { revealAction(command) })
              .foregroundColor(Color(.controlAccentColor))
            Text("|").foregroundColor(Color(.secondaryLabelColor))
            Button("Run Apple script", action: { runAction(command) })
              .foregroundColor(Color(.controlAccentColor))
          }
          .buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
      }
    }
  }
}

struct ShellScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ShellScriptView(
      command: CommandViewModel(
        name: "Run script",
        kind: .shellScript(ShellScriptViewModel.empty())),
      editAction: { _ in },
      revealAction: { _ in },
      runAction: { _ in },
      showContextualMenu: false)
  }
}
