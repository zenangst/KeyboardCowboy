import Bonzai
import Inject
import SwiftUI

struct NewCommandBuiltInView: View {
  @EnvironmentObject var publisher: ConfigurationPublisher
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var kindSelection: BuiltInCommand.Kind = .userMode(mode: .init(id: UUID().uuidString, name: "", isEnabled: true), action: .toggle)
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
            Button(action: { kindSelection = .commandLine(action: .argument(contents: "")) },
                   label: { Text("Open Command Line") })
            Button(action: { kindSelection = .repeatLastWorkflow },
                   label: { Text("Repeat Last Workflow") })
            Button(action: { kindSelection = .windowSwitcher },
                   label: { Text("Window Switcher") })
            Text("Modes")
              .font(.caption)
            Button(action: { kindSelection = .userMode(mode: .init(id: UUID().uuidString, name: "", isEnabled: true), action: .toggle) },
                   label: { Text("User Mode") })
            Text("Macros")
              .font(.caption)
            Button(action: { kindSelection = .macro(action: .record) },
                   label: { Text("Record Macros") })
            Button(action: { kindSelection = .macro(action: .remove) },
                   label: { Text("Remove Macros") })
          } label: {
            switch kindSelection {
            case let .macro(action):
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
    .onChange(of: kindSelection, perform: { _ in
      validation = updateAndValidatePayload()
    })
    .onChange(of: userModeSelection, perform: { _ in
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
  }

  func userMode() -> some View {
    HStack {
      UserModeIconView(size: 24)

      Menu(content: {
        Button(action: { kindSelection = .userMode(mode: userModeSelection, action: .toggle) }, label: {
          Image(systemName: "togglepower")
          Text("Toggle")
        })
        Button(action: { kindSelection = .userMode(mode: userModeSelection, action: .enable) }, label: {
          Image(systemName: "lightswitch.on")
          Text("Enable")
        })
        Button(action: { kindSelection = .userMode(mode: userModeSelection, action: .disable) }, label: {
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
    case let .macro(action):
      validation = true
      newKind = .macro(action: action)
    case let .userMode(_, action):
      validation = !userModeSelection.name.isEmpty
      newKind = .userMode(mode: userModeSelection, action: action)
    case let .commandLine(action):
      validation = true
      newKind = .commandLine(action: action)
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
      onSave: { _, _ in },
    )
    .designTime()
  }
}
