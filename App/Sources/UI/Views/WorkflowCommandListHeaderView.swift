import SwiftUI

struct WorkflowCommandListHeaderView: View {
  @EnvironmentObject var detailPublisher: DetailPublisher
  @Environment(\.openWindow) var openWindow
  private let namespace: Namespace.ID

  init(namespace: Namespace.ID, onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.namespace = namespace
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
            onAction(.updateExecution(workflowId: detailPublisher.data.id,
                                      execution: execution))
          })
        }
      }, label: {
        Image(systemName: "play.fill")
        Text("Run \(detailPublisher.data.execution.rawValue)")
      }, primaryAction: {
        onAction(.runWorkflow(workflowId: detailPublisher.data.id))
      })
      .padding(.horizontal, 2)
      .padding(.top, 3)
      .padding(.bottom, 1)
      .menuStyle(.regular)
      .frame(maxWidth: detailPublisher.data.execution == .concurrent ? 144 : 110,
             alignment: .leading)
      WorkflowCommandListHeaderAddView(namespace)
    }
    .padding(.leading, 24)
    .padding(.trailing, 16)
    .id(detailPublisher.data.id)
  }
}

struct WorkflowCommandListHeaderView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    WorkflowCommandListHeaderView(namespace: namespace, onAction: { _ in })
      .designTime()
  }
}
