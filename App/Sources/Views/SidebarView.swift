import SwiftUI

struct SidebarView: View {
  enum Action {
    case openScene(AppScene)
    case addConfiguration(name: String)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups([GroupViewModel.ID])
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups([GroupViewModel.ID])
  }

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading) {
          Label("Configuration", image: "")
            .frame(maxWidth: .infinity, alignment: .leading)
            .betaFeature("You can create new configurations and switch between them but you can't rename them.",
                         issueNumber: 237) {
              Text("BETA")
                .padding(2)
                .background(Color(.systemYellow))
                .foregroundColor(.black)
                .cornerRadius(4)
                .padding(.trailing, 8)
            }
          SidebarConfigurationView { action in
            switch action {
            case .addConfiguration(let name):
              onAction(.addConfiguration(name: name))
            case .selectConfiguration(let id):
              onAction(.selectConfiguration(id))
            }
          }
          .padding(.trailing, 12)
        }
        .padding(.leading, 12)
        .padding(.top)


        Label("Groups", image: "")
          .padding(.horizontal, 12)
          .padding(.top)
          .padding(.bottom, 4)

        GroupsView(proxy: proxy) { action in
          switch action {
          case .selectGroups(let ids):
            onAction(.selectGroups(ids))
          case .moveGroups(let source, let destination):
            onAction(.moveGroups(source: source, destination: destination))
          case .removeGroups(let ids):
            onAction(.removeGroups(ids))
          case .openScene(let scene):
            onAction(.openScene(scene))
          }
        }
      }
    }
    .labelStyle(SidebarLabelStyle())
  }
}

struct SidebarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView { _ in }
      .designTime()
  }
}
