import SwiftUI
import ModelKit

struct OpenCommandView: View {
  let command: Command
  let editAction: (Command) -> Void
  let revealAction: (Command) -> Void
  let runAction: (Command) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      ZStack {
        IconView(path: command.icon)
      }.frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name).lineLimit(1)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button(action: { editAction(command)}, label: {
              Text("Edit")
            })

            Text("|").foregroundColor(Color(.secondaryLabelColor))

            Button(action: { revealAction(command)}, label: {
              Text("Reveal")
            })

            Text("|").foregroundColor(Color(.secondaryLabelColor))

            Button(action: { runAction(command) }, label: {
              Text("Run")
            })
          }
          .foregroundColor(Color(.controlAccentColor))
          .buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
      }
    }.frame(maxHeight: 32)
  }
}

struct OpenCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    OpenCommandView(
      command: Command.open(OpenCommand.empty()),
      editAction: { _ in },
      revealAction: { _ in },
      runAction: { _ in },
      showContextualMenu: true)
  }
}
