import Bonzai
import SwiftUI

struct GroupItemView: View {
  private let group: GroupViewModel
  private let onAction: (GroupsListView.Action) -> Void
  private let selectionManager: SelectionManager<GroupViewModel>

  init(_ group: GroupViewModel,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsListView.Action) -> Void) {
    self.group = group
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    GroupItemInternalView(
      group,
      selectionManager: selectionManager,
      onAction: onAction
    )
  }
}

private struct GroupItemInternalView: View {
  @State private var isTargeted: Bool = false
  private let selectionManager: SelectionManager<GroupViewModel>
  private let group: GroupViewModel
  private let onAction: (GroupsListView.Action) -> Void

  init(_ group: GroupViewModel,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsListView.Action) -> Void) {
    self.selectionManager = selectionManager
    self.group = group
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
    .background(ItemBackgroundView(group.id, selectionManager: selectionManager))
    .draggable(group)
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


