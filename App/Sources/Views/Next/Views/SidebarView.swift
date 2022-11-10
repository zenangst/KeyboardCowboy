import SwiftUI

struct SidebarView: View {
  enum Action {
    case onSelect([GroupViewModel])
  }
  @ObserveInjection var inject

  @EnvironmentObject var configurationPublisher: ConfigurationPublisher
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
          }
          .badge(group.count)
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
