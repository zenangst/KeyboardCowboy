import SwiftUI

struct WorkflowInfoView: View {
  @Binding var workflow: Workflow

  var body: some View {
    HStack {
      TextField("", text: $workflow.name)
        .textFieldStyle(LargeTextFieldStyle())
      Spacer()
      Toggle("Enabled", isOn: $workflow.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .font(.callout)
    }
  }
}

struct WorkflowInfoView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowInfoView(workflow: .constant(Workflow(name: "Test")))
  }
}
