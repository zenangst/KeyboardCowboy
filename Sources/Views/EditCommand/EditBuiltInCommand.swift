import SwiftUI

struct EditBuiltInCommand: View {
  @ObservedObject private var iO = Inject.observer
  @State private var selection: String = ""
  @State var command: BuiltInCommand {
    willSet { update(newValue) }
  }

  var update: (BuiltInCommand) -> Void

  init(command: BuiltInCommand,
       update: @escaping (BuiltInCommand) -> Void = { _ in }) {
    self._command = State(initialValue: command)
    self.update = update
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open application commands").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        Picker("Command: ", selection: Binding(get: {
          selection
        }, set: { newSelection in
          selection = newSelection
          guard let kind = BuiltInCommand.Kind.allCases
                  .first(where: { $0.id == newSelection }) else { return }
          self.command = BuiltInCommand.init(kind: kind)
        })) {
          ForEach(BuiltInCommand.Kind.allCases) { command in
            Text(command.displayValue)
              .id(command.id)
          }
        }
      }.padding()
    }.onAppear {
      selection = command.kind.rawValue
    }
    .enableInjection()
  }
}

struct EditBuiltInCommand_Previews: PreviewProvider {
  static var previews: some View {
    EditBuiltInCommand(command: .init(kind: .quickRun))
  }
}
