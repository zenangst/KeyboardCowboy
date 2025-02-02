import Bonzai
import Inject
import SwiftUI

struct NewCommandSystemCommandView: View {
  @ObserveInjection var inject
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var kind: SystemCommand.Kind? = nil

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZenLabel("System Command:")

      HStack {
        SystemIconBuilder.icon(kind, size: 24)
        Menu {
          ForEach(SystemCommand.Kind.allCases) { kind in
            Button {
              self.kind = kind
              validation = updateAndValidatePayload()
            } label: {
              HStack {
                Image(systemName: kind.symbol)
                Text(kind.displayValue)
              }
            }
          }
        } label: {
          if let kind {
            HStack {
              Image(systemName: kind.symbol)
              Text(kind.displayValue)
            }
          } else {
            Text("Select System Command")
          }
        }
      }
      .background(NewCommandValidationView($validation))
    }
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      withAnimation { validation = updateAndValidatePayload() }
    })
    .onAppear {
      validation = .unknown
    }
    .enableInjection()
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard let kind else { return .invalid(reason: "Pick a system command.") }

    payload = .systemCommand(kind: kind)

    return .valid
  }
}

struct NewCommandSystemCommandView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .system,
      payload: .systemCommand(kind: .applicationWindows),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
