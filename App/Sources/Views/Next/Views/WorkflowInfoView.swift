import SwiftUI

struct WorkflowInfoView: View {
  @ObserveInjection var inject
  @Binding var workflow: DetailViewModel

  init(_ workflow: Binding<DetailViewModel>) {
    _workflow = workflow
  }

  var body: some View {
    HStack {
      TextField("Workflow name", text: $workflow.name)
        .textFieldStyle(LargeTextFieldStyle())
      Spacer()
      Toggle("", isOn: $workflow.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .tint(Color.green)
        .font(.callout)
    }
    .enableInjection()
  }
}
