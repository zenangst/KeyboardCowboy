import Apps
import SwiftUI

struct WorkflowView: View, Equatable {
  let applicationStore: ApplicationStore
  @Binding var workflow: Workflow

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        WorkflowInfoView(workflow: $workflow)
          .padding([.leading, .trailing, .bottom], 8)
        WorkflowShortcutsView(
          applicationStore: applicationStore,
          workflow: $workflow
        )
          .padding(8)
      }
      .padding()
      .background(Color(.textBackgroundColor))

      VStack(alignment: .leading) {
        WorkflowCommandsListView(workflow: $workflow)
          .padding(8)
      }.padding([.leading, .trailing])
    }
    .background(gradient)
  }

  var gradient: some View {
    LinearGradient(
      gradient: Gradient(
        stops: [
          .init(color: Color(.windowBackgroundColor).opacity(0.25), location: 0.8),
          .init(color: Color(.gridColor).opacity(0.75), location: 1.0),
        ]),
      startPoint: .top,
      endPoint: .bottom)
  }

  static func == (lhs: WorkflowView, rhs: WorkflowView) -> Bool {
    lhs.workflow == rhs.workflow
  }
}

struct WorkflowView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowView(
      applicationStore: ApplicationStore(),
      workflow: .constant(Workflow.designTime(
      .keyboardShortcuts( [
        .init(key: "A", modifiers: [.command]),
        .init(key: "B", modifiers: [.function]),
      ])
    )))
  }
}
