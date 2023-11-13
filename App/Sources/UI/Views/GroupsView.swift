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

  @EnvironmentObject private var contentPublisher: ContentPublisher
  @EnvironmentObject private var publisher: GroupsPublisher
  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>
  @State private var dropDestination: Int?
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let debounceSelectionManager: DebounceSelectionManager<GroupDebounce>
  private let onAction: (Action) -> Void
  private let namespace: Namespace.ID
  private var focus: FocusState<AppFocus?>.Binding

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
                   selectionManager: selectionManager, 
                   contentSelectionManager: contentSelectionManager,
                   onAction: onAction)
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

