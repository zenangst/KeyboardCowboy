import SwiftUI

enum AppFocus: Hashable {
  case groups
  case group(GroupViewModel.ID)
  case workflow(ContentViewModel.ID)
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

  private var focus: FocusState<AppFocus?>.Binding

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
  private let publisher: ContentPublisher
  private let triggerPublisher: TriggerPublisher
  private let infoPublisher: InfoPublisher
  private let commandPublisher: CommandsPublisher

  private var contentFocusPublisher = FocusPublisher<ContentViewModel>()

  init(_ focus: FocusState<AppFocus?>.Binding,
       publisher: ContentPublisher,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       configSelectionManager: SelectionManager<ConfigurationViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupsSelectionManager: SelectionManager<GroupViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher,
       onAction: @escaping (Action, UndoManager?) -> Void) {
    self.focus = focus
    self.publisher = publisher
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.configSelectionManager = configSelectionManager
    self.contentSelectionManager = contentSelectionManager
    self.groupsSelectionManager = groupsSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.triggerPublisher = triggerPublisher
    self.infoPublisher = infoPublisher
    self.commandPublisher = commandPublisher
    self.onAction = onAction
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $navigationPublisher.columnVisibility,
      sidebar: {
        SidebarView(focus,
                    configSelectionManager: configSelectionManager,
                    groupSelectionManager: groupsSelectionManager,
                    contentSelectionManager: contentSelectionManager
        ) { onAction(.sidebar($0), undoManager) }
          .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
          .labelStyle(SidebarLabelStyle())
      },
      content: {
        ContentListView(focus,
                        contentSelectionManager: contentSelectionManager,
                        groupSelectionManager: groupsSelectionManager,
                        onAction: {
          onAction(.content($0), undoManager)

          if case .addWorkflow = $0 {
            Task { @MainActor in focus.wrappedValue = .detail(.name) }
          }
        })
        .onAppear {
          if !publisher.data.isEmpty {
            DispatchQueue.main.async {
              let first = contentSelectionManager.selections.first ?? ""
              focus.wrappedValue = .workflow(contentSelectionManager.lastSelection ?? first)
            }
          }
        }
      },
      detail: {
        DetailView(focus,
                   applicationTriggerSelectionManager: applicationTriggerSelectionManager,
                   commandSelectionManager: commandSelectionManager,
                   keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
                   triggerPublisher: triggerPublisher,
                   infoPublisher: infoPublisher,
                   commandPublisher: commandPublisher,
                   onAction: { onAction(.detail($0), undoManager) })
        .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
          .background(Color(nsColor: .textBackgroundColor).ignoresSafeArea(edges: .all))
          .overlay(alignment: .topTrailing, content: {
            if KeyboardCowboy.env() != .production {
              Rectangle()
                .fill(Gradient(colors: [
                  Color(.systemYellow),
                  Color(nsColor: NSColor.systemYellow.blended(withFraction: 0.3, of: NSColor.black)!)
                ]))
                .frame(width: 75, height: 20)
                .rotationEffect(.degrees(45))
                .offset(x: 30, y: -30)
                .fixedSize()
            }
          })
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
    ContainerView(
      $focus,
      publisher: DesignTime.contentPublisher,
      applicationTriggerSelectionManager: .init(),
      commandSelectionManager: .init(),
      configSelectionManager: .init(),
      contentSelectionManager: .init(),
      groupsSelectionManager: .init(),
      keyboardShortcutSelectionManager: .init(),
      triggerPublisher: DesignTime.triggerPublisher,
      infoPublisher: DesignTime.infoPublisher,
      commandPublisher: DesignTime.commandsPublisher
    ) { _, _ in }
      .designTime()
      .frame(height: 800)
  }
}
