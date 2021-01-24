import SwiftUI
import ModelKit

struct BuiltInView: View {
  let command: Command
  let editAction: (Command) -> Void
  let runAction: (Command) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      Image(systemName: "tornado")
        .frame(width: 32, height: 32)
        .background(Color.accentColor)
        .cornerRadius(4)
      VStack(alignment: .leading, spacing: 2) {
        Text(command.name)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button(action: { editAction(command)}, label: {
              Text("Edit")
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
      Spacer()
    }
  }
}

struct BuiltInView_Previews: PreviewProvider {
  static var previews: some View {
    BuiltInView(command: Command.empty(.builtIn),
                editAction: { _ in },
                runAction: { _ in },
                showContextualMenu: true)
  }
}
