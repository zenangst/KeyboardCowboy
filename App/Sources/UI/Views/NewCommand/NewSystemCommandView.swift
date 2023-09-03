import SwiftUI

struct NewCommandSystemCommandView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var kind: SystemCommand.Kind? = nil

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("System command:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())
      Menu {
        ForEach(SystemCommand.Kind.allCases) { kind in
          Button(kind.displayValue, action: {
            self.kind = kind
            validation = updateAndValidatePayload()
          })
        }
      } label: {
        if let kind {
          Text(kind.displayValue)
        } else {
          Text("Select system command")
        }
      }
      .background(NewCommandValidationView($validation))
    }
    .menuStyle(AppMenuStyle(.init(nsColor: .systemGray),
                                 fixedSize: false))
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      withAnimation { validation = updateAndValidatePayload() }
    })
    .onAppear {
      validation = .unknown
    }
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
