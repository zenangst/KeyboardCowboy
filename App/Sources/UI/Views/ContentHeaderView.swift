import SwiftUI

struct ContentHeaderView: View {
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>
  @EnvironmentObject private var contentPublisher: ContentPublisher
  @EnvironmentObject private var groupsPublisher: GroupsPublisher

  private let namespace: Namespace.ID
  private let onAction: (ContentListView.Action) -> Void

  init(groupSelectionManager: SelectionManager<GroupViewModel>,
       namespace: Namespace.ID,
       onAction: @escaping (ContentListView.Action) -> Void) {
    self.groupSelectionManager = groupSelectionManager
    self.namespace = namespace
    self.onAction = onAction
  }

  var body: some View {
    if let groupId = groupSelectionManager.selections.first,
       let group = groupsPublisher.data.first(where: { $0.id == groupId }) {
      Text("Group")
        .sidebarLabel()
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
      HStack(spacing: 8) {
        GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
          .frame(width: 24, height: 24)
          .padding(4)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(nsColor: .init(hex: group.color)).opacity(0.4))
          )
        VStack(alignment: .leading) {
          Text(group.name)
            .font(.headline)
          Text("Workflows: \(contentPublisher.data.count)")
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        ContentAddWorkflowHeaderView(namespace, onAction: {
          onAction(.addWorkflow(workflowId: UUID().uuidString))
        })
      }
      .padding(.bottom, 4)
      .padding(.leading, 14)
      .id(group)
    }

    Text("Workflows")
      .sidebarLabel()
      .padding(.leading, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
