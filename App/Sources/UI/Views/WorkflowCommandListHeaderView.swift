import Bonzai
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
      ZenLabel("Commands")
      Spacer()
      Menu(content: {
        ForEach(DetailViewModel.Execution.allCases) { execution in
          Button(execution.rawValue, action: {
            onAction(.updateExecution(workflowId: workflowId, execution: execution))
          })
        }
      }, label: {
        Text(publisher.data.execution.rawValue)
          .font(.caption)
      })
      .menuStyle(.zen(.init(color: .systemGray, padding: .large)))
      .fixedSize(horizontal: true, vertical: true)
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
