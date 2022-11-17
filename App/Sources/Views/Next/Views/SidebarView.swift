import SwiftUI

struct SidebarView: View {
  enum Action {
    case openScene(AppScene)
    case onSelect([GroupViewModel])
    case removeGroup(GroupViewModel.ID)
  }
  @ObserveInjection var inject

  @EnvironmentObject var configurationPublisher: ConfigurationPublisher
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
        SidebarConfigurationView()
          .padding([.leading, .trailing], -4)
        Label("Groups", image: "")
      }
      .padding([.leading, .trailing])
      
      List(selection: $groupsPublisher.selections) {
        ForEach(groupsPublisher.models) { group in
          HStack {
            Circle()
              .fill(Color(hex: group.color))
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
            Spacer()
            Button(action: {
              guard let first = groupsPublisher.selections.first else { return }
              onAction(.openScene(.editGroup(first.id))) },
                   label: { Image(systemName: "ellipsis.circle") })
            .buttonStyle(.plain)
            .opacity(groupsPublisher.selections.contains(group) ? 1 : 0)
          }
          .contextMenu(menuItems: {
            Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
            Divider()
            Button("Delete", action: { onAction(.removeGroup(group.id)) })
          })
          .tag(group)
        }
      }
      .onChange(of: groupsPublisher.selections) { newValue in
        onAction(.onSelect(Array(newValue)))
      }
    }
    .labelStyle(HeaderLabelStyle())
    .enableInjection()
  }
}

struct SidebarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView { _ in }
      .designTime()
  }
}
