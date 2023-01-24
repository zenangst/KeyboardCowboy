import SwiftUI

struct SidebarView: View {
  enum Action {
    case openScene(AppScene)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups([GroupViewModel])
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups([GroupViewModel.ID])
  }
  @ObserveInjection var inject

  @EnvironmentObject var groupStore: GroupStore
  @EnvironmentObject var groupsPublisher: GroupsPublisher

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
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
            .tag(group)
        }
        .onMove { source, destination in
          onAction(.moveGroups(source: source, destination: destination))
        }
      }
      .onDeleteCommand(perform: {
        onAction(.removeGroups(groupsPublisher.selections.map { $0.id }))
      })
      .onChange(of: groupsPublisher.selections) { newValue in
        onAction(.selectGroups(Array(newValue)))
      }
    }
    .labelStyle(SidebarLabelStyle())
    .enableInjection()
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
            if let image = group.image {
              Image(nsImage: image)
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
  Button("Remove", action: { onAction(.removeGroups([group.id])) })
}

struct SidebarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView { _ in }
      .designTime()
  }
}
