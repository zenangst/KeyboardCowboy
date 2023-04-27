import SwiftUI

struct SidebarView: View {
  @ObserveInjection var inject

  enum Action {
    case openScene(AppScene)
    case addConfiguration(name: String)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups(Set<GroupViewModel.ID>)
  }

  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let onAction: (Action) -> Void

  init(configSelectionManager: SelectionManager<ConfigurationViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.configSelectionManager = configSelectionManager
    self.groupSelectionManager = groupSelectionManager
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
                .shadow(color: Color(.systemYellow.withSystemEffect(.deepPressed)), radius: 0, x: 1, y: 1)
                .padding(2)
                .background(
                  LinearGradient(stops: [
                    .init(color: Color(.systemYellow.withSystemEffect(.deepPressed)), location: 0.0),
                    .init(color: Color(.systemYellow), location: 1.0)
                  ], startPoint: .top, endPoint: .bottom)
                )
                .foregroundColor(.black)
                .cornerRadius(4)
                .padding(.trailing, 8)
            }
            .padding(.top, 6)
          SidebarConfigurationView(configSelectionManager) { action in
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

        Label("Groups", image: "")
          .padding(.horizontal, 12)
          .padding(.top)
          .padding(.bottom, 8)

        GroupsView(groupSelectionManager) { action in
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
    .debugEdit()
  }
}

struct SidebarView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarView(configSelectionManager: .init(), groupSelectionManager: .init()) { _ in }
      .designTime()
  }
}
