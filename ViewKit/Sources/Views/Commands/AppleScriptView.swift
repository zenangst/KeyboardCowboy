import SwiftUI
import ModelKit

struct AppleScriptView: View {
  let command: Command
  let editAction: (Command) -> Void
  let revealAction: (Command) -> Void
  let runAction: (Command) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      ZStack {
        IconView(path: "/System/Applications/Utilities/Script Editor.app/Contents/Resources/script-editor-dummy.scptd")
        PlayArrowView()
      }.frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 0) {
        Text(command.name).lineLimit(1)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button(action: { editAction(command) }, label: {
              Text("Edit")
            }).foregroundColor(Color(.controlAccentColor))

            Text("|").foregroundColor(Color(.secondaryLabelColor))

            Button(action: { revealAction(command)}, label: {
              Text("Reveal")
            }).foregroundColor(Color(.controlAccentColor))

            Text("|").foregroundColor(Color(.secondaryLabelColor))

            Button(action: { runAction(command) }, label: {
              Text("Run")
            }).foregroundColor(Color(.controlAccentColor))
          }
          .buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
      }
    }.frame(maxHeight: 32)
  }
}

struct AppleScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    AppleScriptView(command: Command.empty(.script),
                    editAction: { _ in },
                    revealAction: { _ in },
                    runAction: { _ in },
                    showContextualMenu: true)
  }
}
