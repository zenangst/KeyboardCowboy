import SwiftUI
import UniformTypeIdentifiers

struct WorkflowCommandListView: View {
  @EnvironmentObject var applicationStore: ApplicationStore
  @Binding private var workflow: DetailViewModel
  @State private var selections = Set<String>()
  @State private var dropOverlayIsVisible: Bool = false
  @State private var dropUrls = Set<URL>()
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
      configuration: .init(lazy: true,
                           uttypes: GenericDroplet<DetailViewModel.CommandViewModel>.writableTypeIdentifiersForItemProvider,
                           spacing: 10),
      dropDelegates: [
        WorkflowCommandDropUrlDelegate(isVisible: $dropOverlayIsVisible,
                                       urls: $dropUrls) {
          onAction(.dropUrls(workflowId: workflow.id, urls: $0))
        }
      ],
      emptyView: {
        VStack {
          Text("You should add some content here.")
            .bold()
          Text("Don't you think?")
        }
        .padding()
        .frame(maxWidth: .infinity)
      },
      scrollProxy: scrollViewProxy,
      itemProvider: {
        NSItemProvider(object: GenericDroplet($0))
      },
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
        .contextMenu(menuItems: { contextMenu(command) })
      }
      .padding()
      .overlay {
        ZStack {
          LinearGradient(stops: [
            .init(color: Color(.systemGreen).opacity(0.75), location: 0.0),
            .init(color: Color(.systemGreen).opacity(0.25), location: 1.0),
          ], startPoint: .bottomTrailing, endPoint: .topLeading)
          .mask(
            RoundedRectangle(cornerRadius: 4)
              .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
              .foregroundColor(Color(.systemGreen))
              .padding(8)
          )
          .shadow(color: .black, radius: 1)

          RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGreen).opacity(0.1))
            .padding(8)
        }
          .opacity(dropOverlayIsVisible ? 1 : 0)
          .animation(.linear, value: dropOverlayIsVisible)
      }
  }

  @ViewBuilder
  private func contextMenu(_ command: Binding<DetailViewModel.CommandViewModel>) -> some View {
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

struct WorkflowCommandListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandListView(.constant(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
