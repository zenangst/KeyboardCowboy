import Bonzai
import Inject
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
    case moveWorkflows(workflowIds: Set<GroupDetailViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<GroupDetailViewModel.ID>, groupId: GroupViewModel.ID)
  }

  @ObserveInjection var inject
  @EnvironmentObject private var publisher: GroupsPublisher
  @Namespace private var namespace
  private let configSelection: SelectionManager<ConfigurationViewModel>
  private let workflowSelection: SelectionManager<GroupDetailViewModel>
  private let groupSelection: SelectionManager<GroupViewModel>
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       configSelection: SelectionManager<ConfigurationViewModel>,
       groupSelection: SelectionManager<GroupViewModel>,
       workflowSelection: SelectionManager<GroupDetailViewModel>,
       onAction: @escaping (Action) -> Void)
  {
    self.focus = focus
    self.configSelection = configSelection
    self.groupSelection = groupSelection
    self.workflowSelection = workflowSelection
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ConfigurationContainerView(
        configSelection: configSelection,
        onAction: onAction,
      )
      .style(.derived)

      ZenDivider()

      GroupsView(namespace, groupSelection: groupSelection,
                 workflowSelection: workflowSelection,
                 onAction: onAction, focus: focus)

      ZenDivider()

      UserModeContainerView(onAction: onAction)
        .style(.derived)
    }
    .enableInjection()
  }
}

#Preview {
  @FocusState var focus: AppFocus?
  return VStack(alignment: .leading) {
    SidebarView(
      $focus,
      configSelection: .init(),
      groupSelection: .init(),
      workflowSelection: .init(),
    ) { _ in }
  }
  .designTime()
}
