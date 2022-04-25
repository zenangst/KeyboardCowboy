import SwiftUI

struct CommandActionsView: View {
  enum Action {
    case edit(Command)
    case reveal(Command)
    case run(Command)
  }
  enum Feature: CaseIterable {
    case edit, reveal, run
  }
  @ObserveInjection var inject
  @ObservedObject var responder: Responder
  @Binding var command: Command
  var features: Set<Feature>
  var action: (Action) -> Void

  init(_ responder: Responder, command: Binding<Command>,
       features: [Feature], action: @escaping (Action) -> Void) {
    _responder = .init(initialValue: responder)
    _command = command
    self.action = action
    self.features = Set<Feature>(features)
  }
  
  var body: some View {
    HStack(spacing: 2) {
      if features.contains(.edit) {
        Text("Edit")
          .foregroundColor(responder.isHighlighted ? Color.white : Color.accentColor)
          .onTapGesture {
            action(.edit(command))
          }
        Text("|")
      }

      if features.contains(.reveal) {
        Text("Reveal").foregroundColor(responder.isHighlighted ? Color.white : Color.accentColor)
        Text("|")
      }

      if features.contains(.run) {
        Text("Run").foregroundColor(responder.isHighlighted ? Color.white : Color.accentColor)
      }
    }
    .font(Font.caption)
    .foregroundColor(Color(.secondaryLabelColor))
    .enableInjection()
  }
}

struct CommandActionsView_Previews: PreviewProvider {
  static var previews: some View {
    CommandActionsView(
      .init(),
      command: .constant(Command.empty(.open)),
      features: CommandActionsView.Feature.allCases,
      action: { _ in }
    )
  }
}
