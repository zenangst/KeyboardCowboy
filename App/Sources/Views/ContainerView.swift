import SwiftUI

enum AppFocus: Hashable {
  case groups
  case workflows
  case detail(Detail)
  case search

  enum Detail: Hashable {
    case name
    case applicationTriggers
    case keyboardShortcuts
    case commands
  }
}

struct ContainerView: View {
  enum Action {
    case openScene(AppScene)
    case sidebar(SidebarView.Action)
    case content(ContentView.Action)
    case detail(DetailView.Action)
  }

  var focus: FocusState<AppFocus?>.Binding

  @EnvironmentObject var groupStore: GroupStore
  @EnvironmentObject var groupsPublisher: GroupsPublisher
  @ObservedObject var navigationPublisher = NavigationPublisher()

  @Environment(\.openWindow) private var openWindow
  let onAction: (Action) -> Void

  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<DetailViewModel.CommandViewModel>
  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupsSelectionManager: SelectionManager<GroupViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  init(focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<DetailViewModel.CommandViewModel>,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupsSelectionManager: SelectionManager<GroupViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.configSelectionManager = configSelectionManager
    self.contentSelectionManager = contentSelectionManager
    self.groupsSelectionManager = groupsSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView(focus,
                    configSelectionManager: configSelectionManager,
                    groupSelectionManager: groupsSelectionManager) { onAction(.sidebar($0)) }
      },
      content: {
        ContentView(focus,
                    contentSelectionManager: contentSelectionManager,
                    groupSelectionManager: groupsSelectionManager,
                    onAction: { action in
          onAction(.content(action))
        })
      },
      detail: {
        DetailView(focus,
                   applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                   commandSelectionManager: commandSelectionManager,
                   keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                   onAction: { onAction(.detail($0)) })
          .edgesIgnoringSafeArea(.top)
      })
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 850, minHeight: 400)
    .onAppear {
      focus.wrappedValue = .groups
    }
  }
}

struct ContainerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContainerView(focus: $focus,
                  applicationTriggerSelectionManager: .init(),
                  commandSelectionManager: .init(),
                  configSelectionManager: .init(),
                  contentSelectionManager: .init(),
                  groupsSelectionManager: .init(),
                  keyboardShortcutSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 800)
  }
}
