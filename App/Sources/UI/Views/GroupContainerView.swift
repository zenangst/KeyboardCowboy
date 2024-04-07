import Bonzai
import SwiftUI

struct GroupContainerView: View {
  @EnvironmentObject private var publisher: GroupsPublisher
  let namespace: Namespace.ID
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let onAction: (SidebarView.Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ namespace: Namespace.ID,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (SidebarView.Action) -> Void,
       focus: FocusState<AppFocus?>.Binding) {
    self.namespace = namespace
    self.contentSelectionManager = contentSelectionManager
    self.groupSelectionManager = groupSelectionManager
    self.onAction = onAction
    self.focus = focus
  }

  var body: some View {
    GroupsHeaderView(namespace,
                     isVisible: .readonly(!publisher.data.isEmpty),
                     onAddGroup: { onAction(.openScene(.addGroup)) })
    .padding(.horizontal, 12)
    .padding(.vertical, 6)

    GroupsListView(focus,
                   namespace: namespace,
                   selectionManager: groupSelectionManager,
                   contentSelectionManager: contentSelectionManager) { action in
      switch action {
      case .selectGroups(let ids):
        onAction(.selectGroups(ids))
      case .moveGroups(let source, let destination):
        onAction(.moveGroups(source: source, destination: destination))
      case .removeGroups(let ids):
        onAction(.removeGroups(ids))
      case .openScene(let scene):
        onAction(.openScene(scene))
      case .moveWorkflows(let workflowIds, let groupId):
        onAction(.moveWorkflows(workflowIds: workflowIds, groupId: groupId))
      case .copyWorkflows(let workflowIds, let groupId):
        onAction(.copyWorkflows(workflowIds: workflowIds, groupId: groupId))
      }
    }
  }
}

private struct GroupsHeaderView: View {
  private let namespace: Namespace.ID
  @Binding private var isVisible: Bool
  private let onAddGroup: () -> Void

  init(_ namespace: Namespace.ID, isVisible: Binding<Bool>, onAddGroup: @escaping () -> Void) {
    _isVisible = isVisible
    self.namespace = namespace
    self.onAddGroup = onAddGroup
  }

  var body: some View {
    HStack {
      ZenLabel(.sidebar) { Text("Groups") }
      Spacer()
      if isVisible {
        SidebarAddGroupButtonView(isVisible: $isVisible,
                                  namespace: namespace, onAction: onAddGroup)
      }
    }
  }
}
