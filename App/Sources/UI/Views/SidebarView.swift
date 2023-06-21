import SwiftUI

struct SidebarView: View {
  @ObserveInjection var inject

  enum Action {
    case refresh
    case openScene(AppScene)
    case addConfiguration(name: String)
    case updateConfiguration(name: String)
    case deleteConfiguraiton(id: ConfigurationViewModel.ID)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups(Set<GroupViewModel.ID>)
    case moveWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
  }

  @Namespace var namespace
  @EnvironmentObject private var publisher: GroupsPublisher
  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.configSelectionManager = configSelectionManager
    self.groupSelectionManager = groupSelectionManager
    self.onAction = onAction
  }

  var body: some View {

    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading) {
        SidebarConfigurationHeaderView()
          .padding(.trailing, 12)
        SidebarConfigurationView(configSelectionManager) { action in
          switch action {
          case .deleteConfiguration(let id):
            onAction(.deleteConfiguraiton(id: id))
          case .updateName(let newName):
            onAction(.updateConfiguration(name: newName))
          case .addConfiguration(let name):
            onAction(.addConfiguration(name: name))
          case .selectConfiguration(let id):
            onAction(.selectConfiguration(id))
          }
        }
        .padding(.trailing, 12)
      }
      .padding(.leading, 12)

      GroupsHeaderView { action in
        switch action {
        case .addGroup:
          onAction(.openScene(.addGroup))
        }
      }
      GroupsView(focus, namespace: namespace, selectionManager: groupSelectionManager) { action in
        switch action {
        case .selectGroups(let ids):
          onAction(.selectGroups(ids))
        case .moveGroups(let source, let destination):
          onAction(.moveGroups(source: source, destination: destination))
        case .removeGroups(let ids):
          onAction(.removeGroups(ids))
        case .openScene(let scene):
          onAction(.openScene(scene))
        case .moveWorkflows(let workflowIds, let groupId):
          onAction(.moveWorkflows(workflowIds: workflowIds, groupId: groupId))
        case .copyWorkflows(let workflowIds, let groupId):
          onAction(.copyWorkflows(workflowIds: workflowIds, groupId: groupId))
        }
      }

      if !publisher.data.isEmpty {
        Button(action: {
          onAction(.openScene(.addGroup))
        }) {
          HStack {
            Image(systemName: "plus.circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: 10)
              .padding(2)
          }
        }
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
        .padding(.leading, 12)
        .padding(.bottom, 6)
        .matchedGeometryEffect(id: "add-group-button", in: namespace)
      }
    }
    .labelStyle(SidebarLabelStyle())
    .debugEdit()
  }
}

struct SidebarView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    SidebarView($focus, configSelectionManager: .init(), groupSelectionManager: .init()) { _ in }
      .designTime()
  }
}
