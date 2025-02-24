import Bonzai
import SwiftUI

struct NewCommandWindowManagementView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation
  @State var selection: WindowManagementCommand.Kind = .center

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZenLabel("Window Management")

      HStack {
        WindowManagementIconView(size: 24)

        Menu {
          ForEach(WindowManagementCommand.Kind.allCases) { kind in
            Button(action: {
              self.selection = kind
              validation = updateAndValidatePayload()
            }, label: {
              Text(kind.displayValue)
            })
          }
        } label: {
          Text(selection.displayValue)
        }
      }
    }
    .onChange(of: validation) { newValue in
      guard newValue == .needsValidation else { return }
      validation = updateAndValidatePayload()
    }
    .onAppear {
      validation = .valid
      payload = .windowManagement(kind: self.selection)
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    payload = .windowManagement(kind: self.selection)
    return .valid
  }
}

struct NewCommandWindowManagementView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .windowManagement,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
