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
      ZenLabel("Built-In Commands")
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack {
        BuiltinIconBuilder.icon(kindSelection, size: 24)

        VStack {

          Menu {
            Button(action: { kindSelection = .commandLine(.argument(contents: "")) },
                   label: { Text("Open Command Line") })
            Button(action: { kindSelection = .repeatLastWorkflow },
                   label: { Text("Repeat Last Workflow") })
            Button(action: { kindSelection = .windowSwitcher },
                   label: { Text("Window Switcher") })
            Text("Modes")
              .font(.caption)
            Button(action: { kindSelection = .userMode(.init(id: UUID().uuidString, name: "", isEnabled: true), .toggle) },
                   label: { Text("User Mode") })
            Text("Macros")
              .font(.caption)
            Button(action: { kindSelection = .macro(.record) },
                   label: { Text("Record Macros") })
            Button(action: { kindSelection = .macro(.remove) },
                   label: { Text("Remove Macros") })
          } label: {
            switch kindSelection {
            case .macro(let action):
              switch action.kind {
              case .record: Text("Record Macro")
              case .remove: Text("Remove Macro")
              }
            case .userMode: Text("User Mode")
            case .commandLine: Text("Open Command Line")
            case .repeatLastWorkflow: Text("Repeat Last Command")
            case .windowSwitcher: Text("Window Switcher")
            }
          }
        }
      }

      switch kindSelection {
      case .macro, .commandLine, .repeatLastWorkflow, .windowSwitcher:
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
      payload = .builtIn(builtIn: .init(kind: kindSelection, notification: nil))
    }
    .menuStyle(.regular)
  }

  func userMode() -> some View {
    HStack {
      UserModeIconView(size: 24)

      Menu(content: {
        Button(action: { kindSelection = .userMode(userModeSelection, .toggle) }, label: {
          Image(systemName: "togglepower")
          Text("Toggle")
        })
        Button(action: { kindSelection = .userMode(userModeSelection, .enable) }, label: {
          Image(systemName: "lightswitch.on")
          Text("Enable")
        })
        Button(action: { kindSelection = .userMode(userModeSelection, .disable) }, label: {
          Image(systemName: "lightswitch.off")
          Text("Disable")
        })
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
    case .commandLine(let action):
      validation = true
      newKind = .commandLine(action)
    case .repeatLastWorkflow:
      validation = true
      newKind = .repeatLastWorkflow
    case .windowSwitcher:
      validation = true
      newKind = .windowSwitcher
    }

    payload = .builtIn(builtIn: .init(kind: newKind, notification: nil))

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
