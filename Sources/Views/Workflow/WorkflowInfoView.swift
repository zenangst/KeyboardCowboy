import SwiftUI

struct WorkflowInfoView: View, Equatable {
  @FocusState var focus: Focus?
  @Binding var workflow: Workflow

  var body: some View {
    HStack {
      TextField("", text: $workflow.name)
        .textFieldStyle(LargeTextFieldStyle())
        .focused($focus, equals: .detail(.info(workflow)))
      Spacer()
      Toggle("Enabled", isOn: $workflow.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .font(.callout)
    }
  }

  static func == (lhs: WorkflowInfoView, rhs: WorkflowInfoView) -> Bool {
    lhs.workflow.name == rhs.workflow.name &&
    lhs.workflow.isEnabled == rhs.workflow.isEnabled
  }
}

struct WorkflowInfoView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowInfoView(workflow: .constant(Workflow(name: "Test")))
  }
}
