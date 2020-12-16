import SwiftUI
import ModelKit

struct ApplicationView: View {
  let command: Command
  let editAction: (Command) -> Void
  let revealAction: (Command) -> Void
  let runAction: (Command) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      if case .application(let model) = command {
        IconView(path: model.application.path)
          .frame(width: 32, height: 32)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(command.name)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button(action: { editAction(command) }, label: {
              Text("Edit")
            })
            .foregroundColor(Color(.controlAccentColor))
            .cursorOnHover(.pointingHand)

            Text("|").foregroundColor(Color(.secondaryLabelColor))

            Button(action: { revealAction(command)}, label: {
              Text("Reveal")
            })
            .foregroundColor(Color(.controlAccentColor))
            .cursorOnHover(.pointingHand)

            Text("|").foregroundColor(Color(.secondaryLabelColor))

            Button(action: { runAction(command) }, label: {
              Text("Run")
            })
            .foregroundColor(Color(.controlAccentColor))
            .cursorOnHover(.pointingHand)
          }
          .buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
      }
      Spacer()
    }
  }
}

struct ApplicationView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ApplicationView(
      command: Command.application(.init(application: .finder())),
      editAction: { _ in },
      revealAction: { _ in },
      runAction: { _ in },
      showContextualMenu: true)
      .frame(maxWidth: 450, maxHeight: 32)
  }
}
