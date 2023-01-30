import SwiftUI

struct SidebarView: View {
  enum Confirm {
    case single(id: GroupViewModel.ID)
    case multiple(ids: [GroupViewModel.ID])

    func contains(_ id: GroupViewModel.ID) -> Bool {
      switch self {
      case .single(let groupId):
        return groupId == id
      case .multiple(let ids):
        return ids.contains(id) && ids.first == id
      }
    }
  }

  enum Action {
    case openScene(AppScene)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups([GroupViewModel])
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups([GroupViewModel.ID])
  }
  @EnvironmentObject private var groupIds: GroupIdsPublisher
  @EnvironmentObject private var groupStore: GroupStore
  @EnvironmentObject private var groupsPublisher: GroupsPublisher

  @State private var confirmDelete: Confirm?

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(alignment: .leading) {
        VStack(alignment: .leading) {
          Label("Configuration", image: "")
          SidebarConfigurationView { action in
            switch action {
            case .selectConfiguration(let id):
              onAction(.selectConfiguration(id))
            }
          }
          .padding([.leading, .trailing], -4)
          Label("Groups", image: "")
        }
        .padding([.leading, .trailing])

        List(selection: $groupsPublisher.selections) {
          ForEach(groupsPublisher.models) { group in
            SidebarItemView(group, onAction: onAction)
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .overlay(content: {
                HStack {
                  Button(action: { confirmDelete = nil },
                         label: { Image(systemName: "x.circle") })
                    .buttonStyle(.gradientStyle(config: .init(nsColor: .brown)))
                    .keyboardShortcut(.escape)
                  Text("Are you sure?")
                    .font(.footnote)
                  Spacer()
                  Button(action: {
                    confirmDelete = nil
                    onAction(.removeGroups(groupsPublisher.selections.map { $0.id }))
                  }, label: { Image(systemName: "trash") })
                    .buttonStyle(.destructiveStyle)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
                .opacity(confirmDelete?.contains(group.id) == true ? 1 : 0)
              })
              .tag(group)
          }
          .onMove { source, destination in
            onAction(.moveGroups(source: source, destination: destination))
          }
        }
        .onDeleteCommand(perform: {
          if groupsPublisher.models.count > 1 {
            confirmDelete = .multiple(ids: groupsPublisher.selections.map(\.id))
          } else if let first = groupsPublisher.models.first {
            confirmDelete = .single(id: first.id)
          }
        })
        .onChange(of: groupsPublisher.selections) { newValue in
          confirmDelete = nil
          groupIds.publish(.init(ids: newValue.map(\.id)))
          onAction(.selectGroups(Array(newValue)))

          if let first = newValue.first {
            proxy.scrollTo(first.id, anchor: .center)
          }
        }
      }
    }
    .labelStyle(SidebarLabelStyle())
  }
}

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
      .opacity(groupsPublisher.selections.contains(group) ? 1 : 0)
      .buttonStyle(.plain)
      .layoutPriority(-1)
    }
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

struct SidebarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView { _ in }
      .designTime()
  }
}
