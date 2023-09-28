import SwiftUI
import UniformTypeIdentifiers

struct WorkflowCommandListView: View {
  static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)

  @Environment(\.openWindow) var openWindow
  var namespace: Namespace.ID
  @ObservedObject private var selectionManager: SelectionManager<CommandViewModel>
  private var focusPublisher = FocusPublisher<CommandViewModel>()
  private let detailPublisher: DetailPublisher
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void
  private let focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       publisher: DetailPublisher,
       selectionManager: SelectionManager<CommandViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.focus = focus
    self.detailPublisher = publisher
    self.namespace = namespace
    self.selectionManager = selectionManager
    self.scrollViewProxy = scrollViewProxy
    self.onAction = onAction
  }

  @ViewBuilder
  var body: some View {
    if detailPublisher.data.commands.isEmpty {
      WorkflowCommandEmptyListView(namespace: namespace, onAction: onAction)
    } else {
      WorkflowCommandListHeaderView(namespace: namespace, onAction: onAction)
        .id(detailPublisher.data.id)
      WorkflowCommandListScrollView(focus,
                                    detailPublisher: detailPublisher,
                                    namespace: namespace,
                                    selectionManager: selectionManager,
                                    scrollViewProxy: scrollViewProxy,
                                    onAction: onAction)
    }
  }
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  @Namespace static var namespace
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowCommandListView($focus,
                            namespace: namespace,
                            publisher: DetailPublisher(DesignTime.detail),
                            selectionManager: .init()) { _ in }
      .frame(height: 900)
  }
}
