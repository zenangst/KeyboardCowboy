import SwiftUI
import Inject

struct WorkflowCommandListView: View {
  @ObserveInjection var inject
  @Binding private var workflow: DetailViewModel
  @State private var selections = Set<String>()
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ model: Binding<DetailViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    _workflow = model
    self.scrollViewProxy = scrollViewProxy
    self.onAction = onAction
  }

  var body: some View {
    EditableStack(
      $workflow.commands,
      configuration: .init(lazy: true, spacing: 10),
      scrollProxy: scrollViewProxy,
      onSelection: { self.selections = $0 },
      onMove: { indexSet, toOffset in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
          workflow.commands.move(fromOffsets: indexSet, toOffset: toOffset)
        }
        onAction(.moveCommand(workflowId: $workflow.id, indexSet: indexSet, toOffset: toOffset))
      },
      onDelete: { indexSet in
        var ids = Set<Command.ID>()
        indexSet.forEach { ids.insert(workflow.commands[$0].id) }
        onAction(.removeCommands(workflowId: $workflow.id, commandIds: ids))
      }) { command, index in
        CommandView(command, workflowId: workflow.id) { action in
          onAction(.commandView(workflowId: workflow.id, action: action))
        }
        .contextMenu {
          Button("Run", action: {})
          Divider()
          Button("Remove", action: {
            if !selections.isEmpty {
              var indexSet = IndexSet()
              selections.forEach { id in
                if let index = workflow.commands.firstIndex(where: { $0.id == id }) {
                  indexSet.insert(index)
                }
              }
              onAction(.removeCommands(workflowId: $workflow.id, commandIds: selections))
            } else {
              onAction(.commandView(workflowId: workflow.id, action: .remove(workflowId: workflow.id, commandId: command.id)))
            }
          })
        }
      }
      .padding()
      .enableInjection()
  }
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandListView(.constant(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
