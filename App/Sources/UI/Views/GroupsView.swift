import SwiftUI
import UniformTypeIdentifiers

struct GroupDebounce: DebounceSnapshot {
  let groups: Set<GroupViewModel.ID>
}

struct GroupsView: View {
  enum Action {
    case openScene(AppScene)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case moveWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case removeGroups(Set<GroupViewModel.ID>)
  }

  var namespace: Namespace.ID

  @EnvironmentObject private var publisher: GroupsPublisher
  @EnvironmentObject private var contentPublisher: ContentPublisher

  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>

  private var focusPublisher = FocusPublisher<GroupViewModel>()
  private var focus: FocusState<AppFocus?>.Binding

  @State private var dropDestination: Int?

  private let debounceSelectionManager: DebounceSelectionManager<GroupDebounce>
  private let moveManager: MoveManager<GroupViewModel> = .init()
  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       selectionManager: SelectionManager<GroupViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _selectionManager = .init(initialValue: selectionManager)
    self.contentSelectionManager = contentSelectionManager
    self.onAction = onAction
    self.namespace = namespace
    self.debounceSelectionManager = .init(.init(groups: selectionManager.selections),
                                          milliseconds: 100,
                                          onUpdate: { snapshot in
      onAction(.selectGroups(snapshot.groups))
    })
  }

  @ViewBuilder
  var body: some View {
    GroupsListView(focus,
                   namespace: namespace,
                   focusPublisher: focusPublisher,
                   selectionManager: selectionManager, 
                   contentSelectionManager: contentSelectionManager,
                   onAction: onAction)
    .focused(focus, equals: .groups)
  }
}

struct GroupsView_Provider: PreviewProvider {
  @Namespace static var namespace
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    GroupsView($focus, namespace: namespace,
               selectionManager: .init(),
               contentSelectionManager: .init(),
               onAction: { _ in })
      .designTime()
  }
}

