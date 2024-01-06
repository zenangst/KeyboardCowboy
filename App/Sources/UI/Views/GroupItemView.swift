import Bonzai
import SwiftUI

struct GroupItemView: View {
  @ObserveInjection var inject
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>

  private let group: GroupViewModel
  private let onAction: (GroupsListView.Action) -> Void
  @State var isTargeted: Bool = false

  init(_ group: GroupViewModel,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsListView.Action) -> Void) {
    self.group = group
    _selectionManager = .init(initialValue: selectionManager)
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 8) {
      GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 0) {
        Text(group.name)
          .allowsTightening(true)
          .minimumScaleFactor(0.8)
          .font(.body)
          .lineLimit(1)

        HStack(spacing: 0) {
          ForEach(group.userModes) { userMode in
            Text(userMode.name)
              .font(.caption2)
              .foregroundColor(.secondary)
              .padding(2)
              .background(Color.accentColor)
              .clipShape(RoundedRectangle(cornerRadius: 4))
              .scaleEffect(0.6, anchor: .leading)
          }
        }
      }
      Spacer()
      Menu(content: { contextualMenu(for: group, onAction: onAction) }) {
        Image(systemName: "ellipsis.circle")
          .resizable()
          .aspectRatio(1, contentMode: .fit)
          .frame(height: 12)
      }
      .opacity(selectionManager.selections.contains(group.id) ? 1 : 0)
      .buttonStyle(.plain)
      .layoutPriority(-1)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .contentShape(Rectangle())
    .background(FillBackgroundView(isSelected: .readonly(selectionManager.selections.contains(group.id))))
    .draggable(group.draggablePayload(prefix: "WG|", selections: selectionManager.selections))
    .dropDestination(String.self, color: .accentColor) { items, location in
      if let payload = items.draggablePayload(prefix: "WG|"),
           let (from, destination) = groupsPublisher.data.moveOffsets(for: group, with: payload) {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
            groupsPublisher.data.move(fromOffsets: IndexSet(from), toOffset: destination)
          }

          onAction(.moveGroups(source: from, destination: destination))
          return true
        } else if let payload = items.draggablePayload(prefix: "W|") {
          onAction(.moveWorkflows(workflowIds: Set(payload), groupId: group.id))
        }
        return false
    }
    .enableInjection()
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (GroupsListView.Action) -> Void) -> some View {
    Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
    Divider()
    Button("Remove", action: {
      onAction(.removeGroups([group.id]))
    })
  }
}
