import SwiftUI
import Inject
import UniformTypeIdentifiers

struct WorkflowCommandListView: View {
  @EnvironmentObject var applicationStore: ApplicationStore
  @ObserveInjection var inject
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
      configuration: .init(lazy: true, spacing: 10),
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

struct WorkflowCommandDropUrlDelegate: EditableDropDelegate {
  static var uttypes: [UTType] = [.fileURL]

  private let onDrop: ([URL]) -> Void
  @State var isValid: Bool = false
  @Binding var isVisible: Bool
  @Binding var urls: Set<URL>

  init(isVisible: Binding<Bool>,
       urls: Binding<Set<URL>>,
       onDrop: @escaping ([URL]) -> Void) {
    _isVisible = isVisible
    _urls = urls
    self.onDrop = onDrop
  }

  func dropExited(info: DropInfo) {
    isVisible = false
    urls.removeAll()
  }

  func dropEntered(info: DropInfo) { }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    let isValid = !info.itemProviders(for: [UTType.fileURL]).isEmpty
    isVisible = isValid

    return isValid ? DropProposal(operation: .copy) : nil
  }

  func validateDrop(info: DropInfo) -> Bool {
    let itemProviders = info.itemProviders(for: [UTType.fileURL])
    isValid = !itemProviders.isEmpty

    for itemProvider in info.itemProviders(for: Self.uttypes) {
      if itemProvider.canLoadObject(ofClass: URL.self) {
        _ = itemProvider.loadObject(ofClass: URL.self) { url, error in
          guard let url else { return }
          self.urls.insert(url)
        }
      }
    }

    return isValid
  }

  func performDrop(info: DropInfo) -> Bool {
    onDrop(Array(urls))
    urls.removeAll()
    return true
  }
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowCommandListView(.constant(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
