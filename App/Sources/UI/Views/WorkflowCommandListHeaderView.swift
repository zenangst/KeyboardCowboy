import SwiftUI

struct WorkflowCommandListHeaderView: View {
  @EnvironmentObject var publisher: CommandsPublisher
  @Environment(\.openWindow) var openWindow
  private let workflowId: String
  private let namespace: Namespace.ID

  init(namespace: Namespace.ID,
       workflowId: String,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.namespace = namespace
    self.workflowId = workflowId
    self.onAction = onAction
  }

  private let onAction: (SingleDetailView.Action) -> Void

  var body: some View {
    HStack {
      Label("Commands", image: "")
      Spacer()
      Menu(content: {
        ForEach(DetailViewModel.Execution.allCases) { execution in
          Button(execution.rawValue, action: {
            onAction(.updateExecution(workflowId: workflowId, execution: execution))
          })
        }
      }, label: {
        Image(systemName: "play.fill")
        Text("Run \(publisher.data.execution.rawValue)")
      }, primaryAction: {
        onAction(.runWorkflow(workflowId: workflowId))
      })
      .padding(.horizontal, 2)
      .menuStyle(.regular)
      .frame(maxWidth: publisher.data.execution == .concurrent ? 144 : 110,
             alignment: .leading)
      WorkflowCommandListHeaderAddView(namespace, workflowId: workflowId)
    }
    .padding(.leading, 24)
    .padding(.trailing, 16)
    .id(workflowId)
  }
}

struct WorkflowCommandListHeaderView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandListHeaderView(namespace: namespace, workflowId: UUID().uuidString, onAction: { _ in })
      .designTime()
  }
}
