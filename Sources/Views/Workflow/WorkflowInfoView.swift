import SwiftUI

struct WorkflowInfoView: View, Equatable {
  @ObservedObject private var iO = Inject.observer
  @FocusState var focus: Focus?
  @Binding var workflow: Workflow

  var body: some View {
    HStack {
      TextField("Workflow name", text: $workflow.name)
        .textFieldStyle(LargeTextFieldStyle())
        .focused($focus, equals: .detail(.info(workflow)))
      Spacer()
      Toggle("", isOn: $workflow.isEnabled)
        .toggleStyle(SwitchToggleStyle())
        .font(.callout)
    }
    .enableInjection()
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
