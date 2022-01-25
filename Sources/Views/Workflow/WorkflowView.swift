import Apps
import SwiftUI

struct WorkflowView: View {
  @Binding var workflow: Workflow

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        WorkflowInfoView(workflow: $workflow)
          .padding([.leading, .trailing, .bottom], 8)
        WorkflowShortcutsView(workflow: $workflow)
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
}

struct WorkflowView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowView(workflow: .constant(Workflow.designTime(
      .keyboardShortcuts( [
        .init(key: "A", modifiers: [.command]),
        .init(key: "B", modifiers: [.function]),
      ])
    )))
  }
}
