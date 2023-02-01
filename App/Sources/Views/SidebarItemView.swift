import SwiftUI

struct SidebarItemView: View {
  @Environment(\.controlActiveState) var controlActiveState
  @EnvironmentObject var groupsPublisher: GroupsPublisher

  private let group: GroupViewModel
  private let onAction: (SidebarView.Action) -> Void

  init(_ group: GroupViewModel, onAction: @escaping (SidebarView.Action) -> Void) {
    self.group = group
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      Circle()
        .fill(Color(hex: group.color)
          .opacity(controlActiveState == .key ? 1 : 0.8))
        .overlay(
          ZStack {
            if let iconPath = group.iconPath {
              Image(nsImage: NSWorkspace.shared.icon(forFile: iconPath))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20)
                .shadow(radius: 2)
            } else if let symbol = group.symbol {
              Image(systemName: symbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16)
            }
          }
        )
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
      .opacity(groupsPublisher.selections.contains(group.id) ? 1 : 0)
      .buttonStyle(.plain)
      .layoutPriority(-1)
    }
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (SidebarView.Action) -> Void) -> some View {
    Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
    Divider()
    Button("Remove", action: {
      onAction(.removeGroups([group.id]))
    })
  }
}
