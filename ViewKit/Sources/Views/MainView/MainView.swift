import SwiftUI
import ModelKit

public struct MainView: View {
  @ObservedObject var store: ViewKitStore
  @AppStorage("groupSelection") var groupSelection: String?
  @AppStorage("workflowSelection") var workflowSelection: String?
  let groupController: GroupController

  public init(store: ViewKitStore,
              groupSelection: String? = nil,
              workflowSelection: String? = nil,
              groupController: GroupController) {
    self.store = store
    self.groupController = groupController

    if let groupSelection = groupSelection { self.groupSelection = groupSelection }
    if let workflowSelection = workflowSelection { self.workflowSelection = workflowSelection }
  }

  @ViewBuilder
  public var body: some View {
    NavigationView {
      SidebarView(store: store,
                  selection: $groupSelection,
                  workflowSelection: $workflowSelection)
        .toolbar(content: { GroupListToolbar(groupController: groupController) })
      ListPlaceHolder()
        .frame(minWidth: 250, idealWidth: 250)
      DetailViewPlaceHolder()
    }
  }
}

struct MainView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let groups = ModelFactory().groupList()
    let context = ViewKitFeatureContext.preview()

    context.workflow.perform(.set(workflow: groups.first!.workflows.first!))

    return MainView(
      store: .init(
        groups: groups,
        context: context),
      groupSelection: groups.first?.id,
      workflowSelection: groups.first?.workflows.first?.id,
      groupController: GroupPreviewController().erase())
      .frame(width: 960, height: 620, alignment: .leading)
  }
}
