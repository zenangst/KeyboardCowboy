import SwiftUI

final class SidebarResolver {
  let store: GroupStore

  init(_ store: GroupStore) {
    self.store = store
  }

  func resolve(_ viewModel: GroupViewModel) -> WorkflowGroup {
    if let workflowGroup = store.group(withId: viewModel.id) {
      return workflowGroup
    }
    fatalError()
  }
}

struct SidebarView: View {
  enum Action {
    case onSelect([GroupViewModel])
  }
  @ObserveInjection var inject

  @EnvironmentObject var configurationPublisher: ConfigurationPublisher
  @EnvironmentObject var groupStore: GroupStore
  @EnvironmentObject var groupsPublisher: GroupsPublisher

  @Environment(\.openWindow) var openWindow

  private let resolver: SidebarResolver
  private let onAction: (Action) -> Void

  init(resolver: SidebarResolver, onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
    self.resolver = resolver
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
          }
          .badge(group.count)
          .tag(group)
          .contextMenu(menuItems: {
            Button("Edit", action: {
              openWindow(value: EditWorkflowGroupWindow.Context.edit(resolver.resolve(group)))
            })
          })
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
    SidebarView(resolver: DesignTime.sidebarResolver) { _ in }
      .designTime()
  }
}
