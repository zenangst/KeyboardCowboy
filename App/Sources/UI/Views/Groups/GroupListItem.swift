import Bonzai
import Inject
import SwiftUI

struct GroupListItem: View {
  private let group: GroupViewModel
  private let onAction: (GroupsList.Action) -> Void
  private let selectionManager: SelectionManager<GroupViewModel>

  init(_ group: GroupViewModel,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsList.Action) -> Void)
  {
    self.group = group
    self.selectionManager = selectionManager
    self.onAction = onAction
  }

  var body: some View {
    GroupItemInternalView(
      group,
      selectionManager: selectionManager,
      onAction: onAction,
    )
  }
}

private struct GroupItemInternalView: View {
  @ObserveInjection var inject
  @State private var isTargeted: Bool = false
  private let selectionManager: SelectionManager<GroupViewModel>
  private let group: GroupViewModel
  private let onAction: (GroupsList.Action) -> Void

  init(_ group: GroupViewModel,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsList.Action) -> Void)
  {
    self.selectionManager = selectionManager
    self.group = group
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 8) {
      GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
        .frame(width: 24)
        .opacity(group.isEnabled ? 1.0 : 0.5)
        .grayscale(group.isEnabled ? 0.0 : 1.0)

      GroupTextView(group)
      ContextualMenuView(selectionManager: selectionManager, group: group, onAction: onAction)
    }
    .style(.item)
    .contentShape(Rectangle())
    .background(ItemBackgroundView(group.id, selectionManager: selectionManager))
    .draggable(group)
    .enableInjection()
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
        .font(group.userModes.isEmpty ? .body : .caption)
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
            .frame(height: 8)
        }
      }
    }
  }
}

private struct ContextualMenuView: View {
  @ObserveInjection var inject
  @ObservedObject private var selectionManager: SelectionManager<GroupViewModel>
  private let group: GroupViewModel
  private let onAction: (GroupsList.Action) -> Void

  init(selectionManager: SelectionManager<GroupViewModel>,
       group: GroupViewModel,
       onAction: @escaping (GroupsList.Action) -> Void)
  {
    self.selectionManager = selectionManager
    self.group = group
    self.onAction = onAction
  }

  var body: some View {
    let isSelected: Bool = selectionManager.selections.contains(group.id)

    Menu(content: { contextualMenu(for: group, onAction: onAction) }) {}
      .opacity(isSelected ? 1 : 0)
      .frame(maxWidth: isSelected ? nil : 0)
      .environment(\.menuCalm, true)
      .environment(\.menuBackgroundColor, Color(.init(hex: group.color)))
      .environment(\.menuPadding, .small)
      .environment(\.menuUnfocusedOpacity, 0)
      .fixedSize()
      .enableInjection()
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (GroupsList.Action) -> Void) -> some View
  {
    Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
    Divider()
    Button("Remove", action: {
      onAction(.removeGroups([group.id]))
    })
  }
}
