import SwiftUI

struct CommandActionsView: View {
  enum Action {
    case edit(Command)
    case reveal(Command)
    case run(Command)
  }
  @ObservedObject var responder: Responder
  @Binding var command: Command
  var action: (Action) -> Void
  
  var body: some View {
    HStack(spacing: 2) {
      Text("Edit")
        .foregroundColor(responder.isHighlighted ? Color.white : Color.accentColor)
        .onTapGesture {
          action(.edit(command))
        }
      Text("|")
      Text("Reveal").foregroundColor(responder.isHighlighted ? Color.white : Color.accentColor)
      Text("|")
      Text("Run").foregroundColor(responder.isHighlighted ? Color.white : Color.accentColor)
    }
    .font(Font.caption)
    .foregroundColor(Color(.secondaryLabelColor))
  }
}

struct CommandActionsView_Previews: PreviewProvider {
  static var previews: some View {
    CommandActionsView(
      responder: .init(),
      command: .constant(Command.empty(.open)),
      action: { _ in }
    )
  }
}
