import SwiftUI

struct WorkflowInfoView: View {
  enum Action {
    case updateName(name: String)
    case setIsEnabled(isEnabled: Bool)
  }

  @Binding var workflow: DetailViewModel
  private var onAction: (Action) -> Void

  init(_ workflow: Binding<DetailViewModel>, onAction: @escaping (Action) -> Void) {
    _workflow = workflow
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 0) {
      TextField("Workflow name", text: $workflow.name)
        .textFieldStyle(LargeTextFieldStyle())
        .onChange(of: workflow.name) { newValue in
          onAction(.updateName(name: newValue))
        }
      Spacer()
      Toggle("", isOn: $workflow.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .tint(Color.green)
        .font(.callout)
        .onChange(of: workflow.isEnabled) { newValue in
          onAction(.setIsEnabled(isEnabled: newValue))
        }
    }
    .frame(minHeight: 32)
  }
}
