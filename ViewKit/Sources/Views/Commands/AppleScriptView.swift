import SwiftUI

struct AppleScriptView: View {
  let command: CommandViewModel
  let editAction: (CommandViewModel) -> Void
  let revealAction: (CommandViewModel) -> Void
  let runAction: (CommandViewModel) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      ZStack {
        IconView(icon: Icon(
                  identifier: "script-editor-file",
                  path: "/System/Applications/Utilities/Script Editor.app/Contents/Resources/script-editor-dummy.scptd")
        )
        PlayArrowView()
      }.frame(width: 32, height: 32)

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

struct AppleScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    AppleScriptView(command: CommandViewModel(id: UUID().uuidString, name: "Run script",
                                              kind: .appleScript(AppleScriptViewModel.empty())),
                    editAction: { _ in },
                    revealAction: { _ in },
                    runAction: { _ in },
                    showContextualMenu: false)
  }
}
