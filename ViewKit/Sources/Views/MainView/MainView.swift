import SwiftUI

public typealias GroupController = AnyViewController<[GroupViewModel], GroupList.Action>
public typealias WorkflowController = AnyViewController<WorkflowViewModel?, WorkflowList.Action>
public typealias CommandController = AnyViewController<[CommandViewModel], CommandListView.Action>
public typealias OpenPanelController = AnyViewController<String, OpenPanelAction>
public typealias KeyboardShortcutController = AnyViewController<[KeyboardShortcutViewModel], KeyboardShortcutListView.Action>
public typealias ApplicationProvider = AnyStateController<[ApplicationViewModel]>

public struct MainView: View {
  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var groupController: GroupController
  @ObservedObject var keyboardShortcutController: KeyboardShortcutController
  @ObservedObject var workflowController: WorkflowController
  @ObservedObject var openPanelController: OpenPanelController
  @EnvironmentObject var userSelection: UserSelection
  @State private var searchText: String = ""

  public init(applicationProvider: ApplicationProvider,
              commandController: CommandController,
              groupController: GroupController,
              keyboardShortcutController: KeyboardShortcutController,
              openPanelController: OpenPanelController,
              workflowController: WorkflowController) {
    self.applicationProvider = applicationProvider
    self.commandController = commandController
    self.groupController = groupController
    self.keyboardShortcutController = keyboardShortcutController
    self.openPanelController = openPanelController
    self.workflowController = workflowController
  }

  public var body: some View {
    NavigationView {
      sidebar
      if searchText.isEmpty {
        browseContext
      } else {
        searchContext
      }
    }
  }
}

// MARK: Extensions

private extension MainView {
  var sidebar: some View {
    VStack(alignment: .leading) {
      SearchField(query: $searchText)
        .frame(height: 48)
        .padding(.horizontal, 12)
      GroupList(controller: groupController)
    }.frame(minWidth: 200)
  }

  var browseContext: some View {
    HSplitView {
      if let group = userSelection.group {
        WorkflowList(group: Binding(
                      get: { group },
                      set: { userSelection.group = $0 }),
                     workflowController: workflowController)
          .frame(minWidth: 250, idealWidth: 250, maxWidth: 300)
          .padding(.top, 1)
      }

      if let workflow = userSelection.workflow {
        WorkflowView(
          applicationProvider: applicationProvider,
          commandController: commandController,
          keyboardShortcutController: keyboardShortcutController,
          openPanelController: openPanelController,
          workflow:
            Binding(
              get: { workflow },
              set: { workflow in
                workflowController.action(.updateWorkflow(workflow))()
              }))
          .background(Color(.textBackgroundColor))
          .frame(minWidth: 400)
          .edgesIgnoringSafeArea(.top)
      }
    }
  }

  var searchContext: some View {
    Text("Not yet implemented")
  }
}

struct MainView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    MainView(applicationProvider: ApplicationPreviewProvider().erase(),
             commandController: CommandPreviewController().erase(),
             groupController: GroupPreviewController().erase(),
             keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
             openPanelController: OpenPanelPreviewController().erase(),
             workflowController: WorkflowPreviewController().erase())
      .environmentObject(UserSelection())
      .frame(width: 960, height: 600, alignment: .leading)
  }
}

private final class ApplicationPreviewProvider: StateController {
  let state = [ApplicationViewModel]()
}

private final class CommandPreviewController: ViewController {
  let state = ModelFactory().workflowDetail().commands
  func perform(_ action: CommandListView.Action) {}
}

private final class GroupPreviewController: ViewController {
  let state = ModelFactory().groupList()
  func perform(_ action: GroupList.Action) {}
}

private final class WorkflowPreviewController: ViewController {
  let state = ModelFactory().workflowList().first
  func perform(_ action: WorkflowList.Action) {}
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}

private final class KeyboardShortcutPreviewController: ViewController {
  let state: [KeyboardShortcutViewModel] = ModelFactory().keyboardShortcuts()
  func perform(_ action: KeyboardShortcutListView.Action) {}
}

