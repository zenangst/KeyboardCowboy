import SwiftUI

struct WorkflowCommandListView: View {
  @Binding private var workflow: DetailViewModel
  @State private var selections = Set<String>()
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void
  private let onNewCommand: () -> Void

  init(_ model: Binding<DetailViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil,
       onNewCommand: @escaping () -> Void,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    _workflow = model
    self.scrollViewProxy = scrollViewProxy
    self.onNewCommand = onNewCommand
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Label("Commands:", image: "")
        Spacer()
        Group {
          Menu(content: {
            ForEach(DetailViewModel.Flow.allCases) {
              Button($0.rawValue, action: {})
            }
          }, label: {
            Text("Run \(workflow.flow.rawValue)")
          }, primaryAction: {
          })
          .fixedSize()
        }
        .opacity(workflow.commands.isEmpty ? 0 : 1)
        Button(action: onNewCommand) {
          HStack(spacing: 4) {
            Image(systemName: "plus")
          }
        }
        .padding(4)
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
      }
      .padding([.leading, .bottom], 8)
      .padding(.trailing, 2)

      EditableStack(
        $workflow.commands,
        lazy: true,
        scrollProxy: scrollViewProxy,
        spacing: 10,
        onSelection: { self.selections = $0 },
        onMove: { indexSet, toOffset in
          withAnimation {
            workflow.commands.move(fromOffsets: indexSet, toOffset: toOffset)
          }
          onAction(.moveCommand(workflowId: $workflow.id, indexSet: indexSet, toOffset: toOffset))
        },
        onDelete: { indexSet in
          var ids = Set<Command.ID>()
          indexSet.forEach { ids.insert(workflow.commands[$0].id) }
          onAction(.removeCommands(workflowId: $workflow.id, commandIds: ids))
        }) { command in
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
    }
    .padding()
  }
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandListView(.constant(DesignTime.detail), onNewCommand: {}) { _ in }
      .frame(height: 900)
  }
}
