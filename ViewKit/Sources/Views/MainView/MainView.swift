import SwiftUI

public typealias GroupController = AnyViewController<[GroupViewModel], GroupList.Action>
public typealias WorkflowController = AnyViewController<WorkflowViewModel?, WorkflowList.Action>
public typealias CommandController = AnyViewController<[CommandViewModel], CommandListView.Action>
public typealias OpenPanelController = AnyViewController<String, OpenPanelAction>
public typealias ApplicationProvider = AnyStateController<[ApplicationViewModel]>

public struct MainView: View {
  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var commandController: CommandController
  @ObservedObject var groupController: GroupController
  @ObservedObject var workflowController: WorkflowController
  @ObservedObject var openPanelController: OpenPanelController
  @EnvironmentObject var userSelection: UserSelection
  @State private var searchText: String = ""

  public init(applicationProvider: ApplicationProvider,
              commandController: CommandController,
              groupController: GroupController,
              openPanelController: OpenPanelController,
              workflowController: WorkflowController) {
    self.applicationProvider = applicationProvider
    self.commandController = commandController
    self.groupController = groupController
    self.openPanelController = openPanelController
    self.workflowController = workflowController
  }

  public var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        TextField("Search", text: $searchText)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .frame(height: 48)
          .padding(.horizontal, 12)
        GroupList(controller: groupController)
      }
      .frame(minWidth: 200)

      if let group = userSelection.group {
        WorkflowList(group: Binding(
                      get: { group },
                      set: { userSelection.group = $0 }),
                     workflowController: workflowController)
          .frame(minWidth: 250)
          .padding(.top, 1)
      }

      if let workflow = userSelection.workflow {
        WorkflowView(
          applicationProvider: applicationProvider,
          commandController: commandController,
          openPanelController: openPanelController,
          workflow:
            Binding(
              get: { workflow },
              set: { workflow in
                workflowController.action(.updateWorkflow(workflow))()
              }))
          .background(Color(.textBackgroundColor))
          .edgesIgnoringSafeArea(.top)
      }
    }
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
