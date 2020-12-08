import SwiftUI
import ModelKit

public struct MainView: View {
  @EnvironmentObject var userSelection: UserSelection
  let factory: ViewFactory
  @ObservedObject var searchController: SearchController
  let applicationProvider: ApplicationProvider
  let commandController: CommandController
  let groupController: GroupController
  let openPanelController: OpenPanelController
  let workflowController: WorkflowController

  public init(factory: ViewFactory,
              applicationProvider: ApplicationProvider,
              commandController: CommandController,
              groupController: GroupController,
              openPanelController: OpenPanelController,
              searchController: SearchController,
              workflowController: WorkflowController) {
    self.factory = factory
    self.applicationProvider = applicationProvider
    self.commandController = commandController
    self.groupController = groupController
    self.openPanelController = openPanelController
    self.searchController = searchController
    self.workflowController = workflowController
  }

  @ViewBuilder
  public var body: some View {
    NavigationView {
      sidebar.frame(minWidth: 225)
      EmptyView()
      if let workflow = userSelection.workflow,
         let group = userSelection.group {
        factory.workflowDetail(Binding<Workflow>(
          get: {
            workflow
          }, set: {
            userSelection.workflow = $0
            workflowController.perform(.updateWorkflow($0, in: group))
          }
        ), group: group)
        .environmentObject(userSelection)
        .id(workflow.id)
      }
    }
  }
}

// MARK: Extensions

private extension MainView {
  var sidebar: some View {
    factory.groupList()
      .toolbar(content: {
        ToolbarItemGroup(placement: .primaryAction) {
          Button(action: toggleSidebar,
                 label: {
                  Image(systemName: "sidebar.left")
                    .renderingMode(.template)
                    .foregroundColor(Color(.systemGray))
                 })
            .help("Toggle Sidebar")
        }
      })
  }

  func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(
      #selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
}

struct MainView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    DesignTimeFactory().mainView()
      .environmentObject(UserSelection(
                          group: ModelFactory().groupList().first!,
                          workflow: ModelFactory().groupList().first!.workflows.first))
      .frame(width: 960, height: 620, alignment: .leading)
  }
}
