import SwiftUI

struct ContainerView: View {
  enum Focus {
    case sidebar
    case content
    case detail
  }

  enum Action {
    case openScene(AppScene)
    case sidebar(SidebarView.Action)
    case content(ContentView.Action)
    case detail(DetailView.Action)
  }

  @EnvironmentObject var groupStore: GroupStore
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var navigationPublisher = NavigationPublisher()

  @Environment(\.openWindow) private var openWindow
  var focus: FocusState<Focus?>.Binding
  let onAction: (Action) -> Void

  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupsSelectionManager: SelectionManager<GroupViewModel>

  init(focus: FocusState<Focus?>.Binding,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupsSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.configSelectionManager = configSelectionManager
    self.contentSelectionManager = contentSelectionManager
    self.groupsSelectionManager = groupsSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView(configSelectionManager: configSelectionManager,
                    groupSelectionManager: groupsSelectionManager) { onAction(.sidebar($0)) }
          .focused(focus, equals: .sidebar)
      },
      content: {
        ContentView(contentSelectionManager: contentSelectionManager,
                    groupSelectionManager: groupsSelectionManager) { action in
          onAction(.content(action))
        }
        .focused(focus, equals: .content)
      },
      detail: {
        DetailView(onAction: { onAction(.detail($0)) })
          .focused(focus, equals: .detail)
          .edgesIgnoringSafeArea(.top)
      })
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 850, minHeight: 400)
  }
}

struct ContainerView_Previews: PreviewProvider {
  @FocusState static var focus: ContainerView.Focus?

  static var previews: some View {
    ContainerView(focus: $focus,
                  configSelectionManager: .init(),
                  contentSelectionManager: .init(),
                  groupsSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 800)
  }
}
