import Inject
import SwiftUI

struct NewCommandBuiltInView: View {
  @EnvironmentObject var publisher: ConfigurationPublisher
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var kindSelection: BuiltInCommand.Kind = .userMode(.init(id: UUID().uuidString, name: "", isEnabled: true), .toggle)
  @State private var userModeSelection: UserMode = .init(id: UUID().uuidString, name: "", isEnabled: true)

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Built-In Commands") }, icon: { EmptyView() })
        .frame(maxWidth: .infinity, alignment: .leading)
        .labelStyle(HeaderLabelStyle())

      HStack {
        Menu(content: {
          Button(action: { kindSelection = .userMode(userModeSelection, .toggle) }, label: { Text("Toggle") })
          Button(action: { kindSelection = .userMode(userModeSelection, .enable) }, label: { Text("Enable") })
          Button(action: { kindSelection = .userMode(userModeSelection, .disable) }, label: { Text("Disable") })
        }, label: {
          Text(kindSelection.displayValue)
        })

        Menu(content: {
          ForEach(publisher.data.userModes) { userMode in
            Button(action: { userModeSelection = userMode },
                   label: { Text(userMode.name) })
          }
        }, label: {
          Text(publisher.data.userModes.first(where: { $0.id == userModeSelection.id })?.name ?? "Pick a User Mode")
        })
      }
    }
    .onChange(of: kindSelection, perform: { newValue in
      validation = updateAndValidatePayload()
    })
    .onChange(of: userModeSelection, perform: { newValue in
      validation = updateAndValidatePayload()
    })
    .onChange(of: validation) { newValue in
      guard newValue == .needsValidation else { return }
      validation = updateAndValidatePayload()
    }
    .onAppear {
      validation = .needsValidation
      payload = .builtIn(builtIn: .init(kind: kindSelection, notification: false))
    }
    .menuStyle(.regular)
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    let newKind: BuiltInCommand.Kind = switch kindSelection {
      case .userMode(_, let action): .userMode(userModeSelection, action)
    }

    payload = .builtIn(builtIn: .init(kind: newKind, notification: false))

    return !userModeSelection.name.isEmpty ? .valid : .invalid(reason: "Please select a User Mode.")
  }
}

struct NewCommandBuiltInView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .builtIn,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
