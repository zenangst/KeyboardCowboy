import SwiftUI
import UniformTypeIdentifiers

struct WorkflowCommandListView: View {
  @ObserveInjection var inject
  @Environment(\.openWindow) var openWindow
  @EnvironmentObject var applicationStore: ApplicationStore
  @ObservedObject private var detailPublisher: DetailPublisher
  @State private var selections = Set<String>()
  @State private var dropOverlayIsVisible: Bool = false
  @State private var dropUrls = Set<URL>()
  private var focusManager = EditableFocusManager<DetailViewModel.CommandViewModel.ID>()
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ detailPublisher: DetailPublisher,
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    _detailPublisher = .init(initialValue: detailPublisher)
    self.scrollViewProxy = scrollViewProxy
    self.onAction = onAction
  }

  var body: some View {
    EditableStack(
      $detailPublisher.data.commands,
      configuration: .init(lazy: true,
                           uttypes: GenericDroplet<DetailViewModel.CommandViewModel>.writableTypeIdentifiersForItemProvider,
                           spacing: 10),
      dropDelegates: [
        WorkflowCommandDropUrlDelegate(isVisible: $dropOverlayIsVisible,
                                       urls: $dropUrls) {
                                         onAction(.dropUrls(workflowId: detailPublisher.data.id, urls: $0))
                                       }
      ],
      emptyView: {
        VStack {
          Button(action: {
            openWindow(value: NewCommandWindow.Context.newCommand(workflowId: detailPublisher.data.id))
          }) {
            Text("Add a command")
              .padding(.vertical, 4)
              .padding(.horizontal, 16)
          }
          .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen)))
        }
        .padding()
        .frame(maxWidth: .infinity)
      },
      focusManager: focusManager,
      scrollProxy: scrollViewProxy,
      itemProvider: {
        NSItemProvider(object: GenericDroplet($0))
      },
      onSelection: { self.selections = $0 },
      onMove: { indexSet, toOffset in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
          detailPublisher.data.commands.move(fromOffsets: indexSet, toOffset: toOffset)
        }
        onAction(.moveCommand(workflowId: $detailPublisher.data.id, indexSet: indexSet, toOffset: toOffset))
      },
      onDelete: { indexSet in
        var ids = Set<Command.ID>()
        indexSet.forEach { ids.insert(detailPublisher.data.commands[$0].id) }
        onAction(.removeCommands(workflowId: $detailPublisher.data.id, commandIds: ids))
      }) { command, index in
        CommandView(command.wrappedValue, workflowId: detailPublisher.data.id) { action in
          onAction(.commandView(workflowId: detailPublisher.data.id, action: action))
        }
        .contextMenu(menuItems: { contextMenu(command) })
      }
      .padding()
      .overlay {
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
        .opacity(dropOverlayIsVisible ? 1 : 0)

        Color(.systemGreen).opacity(0.1)
          .cornerRadius(4)
          .padding(8)
          .opacity(dropOverlayIsVisible ? 1 : 0)
          .animation(.linear, value: dropOverlayIsVisible)
      }
      .enableInjection()
  }

  @ViewBuilder
  private func contextMenu(_ command: Binding<DetailViewModel.CommandViewModel>) -> some View {
    Button("Run", action: {})
    Divider()
    Button("Remove", action: {
      if !selections.isEmpty {
        var indexSet = IndexSet()
        selections.forEach { id in
          if let index = detailPublisher.data.commands.firstIndex(where: { $0.id == id }) {
            indexSet.insert(index)
          }
        }
        onAction(.removeCommands(workflowId: detailPublisher.data.id, commandIds: selections))
      } else {
        onAction(.commandView(workflowId: detailPublisher.data.id, action: .remove(workflowId: detailPublisher.data.id, commandId: command.id)))
      }
    })
  }
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandListView(DetailPublisher(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
