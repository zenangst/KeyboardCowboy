import SwiftUI

struct GroupItemView: View {
  @ObserveInjection var inject
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>

  private let proxy: ScrollViewProxy
  private let focusPublisher: FocusPublisher<GroupViewModel>
  private let group: GroupViewModel
  private let onAction: (GroupsView.Action) -> Void
  @State var isTargeted: Bool = false

  init(_ group: GroupViewModel,
       proxy: ScrollViewProxy,
       focusPublisher: FocusPublisher<GroupViewModel>,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsView.Action) -> Void) {
    self.group = group
    self.proxy = proxy
    self.focusPublisher = focusPublisher
    _selectionManager = .init(initialValue: selectionManager)
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
        .frame(width: 24)
      Text(group.name)
        .font(.body)
        .lineLimit(1)
      Spacer()
      Menu(content: { contextualMenu(for: group, onAction: onAction) }) {
        Image(systemName: "ellipsis.circle")
          .resizable()
          .aspectRatio(1, contentMode: .fit)
          .frame(height: 16)
      }
      .opacity(selectionManager.selections.contains(group.id) ? 1 : 0)
      .buttonStyle(.plain)
      .layoutPriority(-1)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .background(
      FocusView(focusPublisher, element: Binding.readonly(group),
                isTargeted: $isTargeted,
                selectionManager: selectionManager,
                cornerRadius: 4, style: .list)
    )
    .draggable(group.draggablePayload(prefix: "WG|", selections: selectionManager.selections))
    .dropDestination(for: String.self, action: { items, location in
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
    }, isTargeted: { newValue in
      isTargeted = newValue
    })
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (GroupsView.Action) -> Void) -> some View {
    Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
    Divider()
    Button("Remove", action: {
      onAction(.removeGroups([group.id]))
    })
  }
}
