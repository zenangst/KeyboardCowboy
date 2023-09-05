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
    case content(ContentListView.Action)
    case detail(DetailView.Action)
  }

  var focus: FocusState<AppFocus?>.Binding

  @Namespace var namespace
  @Environment(\.undoManager) var undoManager
  @ObservedObject var navigationPublisher = NavigationPublisher()

  private let onAction: (Action, UndoManager?) -> Void
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let configSelectionManager: SelectionManager<ConfigurationViewModel>
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupsSelectionManager: SelectionManager<GroupViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  private var contentFocusPublisher = FocusPublisher<ContentViewModel>()

  init(focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupsSelectionManager: SelectionManager<GroupViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (Action, UndoManager?) -> Void) {
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
                    groupSelectionManager: groupsSelectionManager) { onAction(.sidebar($0), undoManager) }
          .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
          .labelStyle(SidebarLabelStyle())
      },
      content: {
        ContentListView(focus,
                        contentSelectionManager: contentSelectionManager,
                        groupSelectionManager: groupsSelectionManager,
                        focusPublisher: contentFocusPublisher,
                        onAction: { onAction(.content($0), undoManager) })
        .focused(focus, equals: .workflows)
      },
      detail: {
        DetailView(focus,
                   applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                   commandSelectionManager: commandSelectionManager,
                   keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                   onAction: { onAction(.detail($0), undoManager) })
          .edgesIgnoringSafeArea(.top)
          .background(Color(nsColor: .textBackgroundColor).ignoresSafeArea(edges: .all))
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
                  keyboardShortcutSelectionManager: .init()) { _, _ in }
      .designTime()
      .frame(height: 800)
  }
}
