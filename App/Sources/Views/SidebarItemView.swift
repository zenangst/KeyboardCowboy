import SwiftUI

struct SidebarItemView: View {
  @ObserveInjection var inject
  @Environment(\.controlActiveState) var controlActiveState
  @EnvironmentObject var groupsPublisher: GroupsPublisher

  private let selectionManager: SelectionManager<GroupViewModel>
  private let group: GroupViewModel
  private let onAction: (GroupsView.Action) -> Void

  init(_ group: GroupViewModel,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsView.Action) -> Void) {
    self.group = group
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
        .frame(width: 24)
      Text(group.name)
        .font(.body)
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
    .debugEdit()
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
