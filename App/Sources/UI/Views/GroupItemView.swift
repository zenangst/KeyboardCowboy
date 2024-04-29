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
      GroupTextView(group)
      ContextualMenuView(selectionManager: selectionManager, group: group, onAction: onAction)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .contentShape(Rectangle())
    .background(ItemBackgroundView(group.id, selectionManager: selectionManager))
    .draggable(group)
  }
}

private struct GroupTextView: View {
  private let group: GroupViewModel

  init(_ group: GroupViewModel) {
    self.group = group
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(group.name)
        .allowsTightening(true)
        .minimumScaleFactor(0.8)
        .font(.body)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)

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
  }
}

private struct ContextualMenuView: View {
  @ObservedObject private var selectionManager: SelectionManager<GroupViewModel>
  private let group: GroupViewModel
  private let onAction: (GroupsListView.Action) -> Void

  init(selectionManager: SelectionManager<GroupViewModel>, 
       group: GroupViewModel,
       onAction: @escaping (GroupsListView.Action) -> Void) {
    self.selectionManager = selectionManager
    self.group = group
    self.onAction = onAction
  }

  var body: some View {
    let isSelected: Bool = selectionManager.selections.contains(group.id)

    Menu(content: { contextualMenu(for: group, onAction: onAction) }) {
      Image(systemName: "ellipsis.circle")
        .resizable()
        .aspectRatio(1, contentMode: .fit)
        .frame(height: 12)
    }
    .opacity(isSelected ? 1 : 0)
    .frame(maxWidth: isSelected ? nil : 0)
    .buttonStyle(.plain)
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

