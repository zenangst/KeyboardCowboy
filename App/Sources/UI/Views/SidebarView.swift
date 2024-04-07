import Bonzai
import SwiftUI

struct SidebarView: View {
  enum Action {
    case refresh
    case openScene(AppScene)
    case addConfiguration(name: String)
    case userMode(UserModesView.Action)
    case updateConfiguration(name: String)
    case deleteConfiguration(id: ConfigurationViewModel.ID)
    case selectConfiguration(ConfigurationViewModel.ID)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups(Set<GroupViewModel.ID>)
    case moveWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
  }

  @EnvironmentObject private var publisher: GroupsPublisher
  @Namespace private var namespace
  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.configSelectionManager = configSelectionManager
    self.groupSelectionManager = groupSelectionManager
    self.contentSelectionManager = contentSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ConfigurationContainerView(configSelectionManager: configSelectionManager,
                                 onAction: onAction)

      GroupContainerView(namespace,
                         contentSelectionManager: contentSelectionManager,
                         groupSelectionManager: groupSelectionManager,
                         onAction: onAction,
                         focus: focus)

      UserModeContainerView(onAction: onAction)
    }
  }
}

struct SidebarView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    VStack(alignment: .leading) {
      SidebarView(
        $focus,
        configSelectionManager: .init(),
        groupSelectionManager: .init(),
        contentSelectionManager: .init()
      ) { _ in }
    }
      .designTime()
  }
}
