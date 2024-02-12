import Bonzai
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
      HStack {
        switch kindSelection {
        case .macro(let macroAction):
          switch macroAction.kind {
          case .record:
            MacroIconView(.record, size: 24)
          case .remove:
            MacroIconView(.remove, size: 24)
          }
        case .userMode:
          let path = Bundle.main.bundleURL.path
          IconView(icon: .init(bundleIdentifier: path, path: path), size: CGSize(width: 24, height: 24))
        }

        VStack {
          ZenLabel("Built-In Commands")
            .frame(maxWidth: .infinity, alignment: .leading)

          Menu {
            Button(action: { kindSelection = .userMode(.init(id: UUID().uuidString, name: "", isEnabled: true), .toggle) },
                   label: { Text("User Mode") })
            Button(action: { kindSelection = .macro(.record) },
                   label: { Text("Record Macros") })
            Button(action: { kindSelection = .macro(.remove) },
                   label: { Text("Remove Macros") })
          } label: {
            switch kindSelection {
              case .macro(let action):
                switch action.kind {
                  case .record:
                    Text("Record Macro")
                  case .remove:
                    Text("Remove Macro")
                }
              case .userMode:
                Text("User Mode")
            }
          }
        }
      }

      switch kindSelection {
        case .macro:
          EmptyView()
        case .userMode:
          userMode()
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

  func userMode() -> some View {
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

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    let validation: Bool
    let newKind: BuiltInCommand.Kind
    switch kindSelection {
    case .macro(let action):
      validation = true
      newKind = .macro(action)
    case .userMode(_, let action):
      validation = !userModeSelection.name.isEmpty
      newKind = .userMode(userModeSelection, action)
    }

    payload = .builtIn(builtIn: .init(kind: newKind, notification: false))

    return validation ? .valid : .invalid(reason: "Please select a User Mode.")
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
