import SwiftUI
import ModelKit

public struct MainView: View {
  @ObservedObject var store: ViewKitStore
  @AppStorage("groupSelection") var groupSelection: String?
  @AppStorage("workflowSelection") var workflowSelection: String?
  @AppStorage("workflowSelections") var workflowSelections: String?
  let groupController: GroupsController

  public init(store: ViewKitStore,
              groupSelection: String? = nil,
              workflowSelection: String? = nil,
              groupController: GroupsController) {
    self.store = store
    self.groupController = groupController

    if let groupSelection = groupSelection { self.groupSelection = groupSelection }
    if let workflowSelection = workflowSelection { self.workflowSelection = workflowSelection }
  }

  public var body: some View {
    NavigationView {
      SidebarView(store: store)
        .toolbar(content: { GroupListToolbar(groupController: groupController) })

      WorkflowList(
        store: store,
        workflowsController: store.context.workflows,
        workflowSelections: Binding<Set<String>>(
          get: {
            if let workflowSelections = workflowSelections {
              return Set<String>(workflowSelections.split(separator: ",").compactMap(String.init))
            } else {
              return Set<String>()
            }
          },
          set: { newValue in
            workflowSelections = Array(newValue).joined(separator: ",")
            workflowSelection = newValue.first
          })
      )
      .placeholder(if: store.context.workflows.isEmpty,
        Button(action: { store.context.workflows.perform(.create(groupId: groupSelection)) },
               label: { Text("Add workflow") })
      )
      .frame(minWidth: 250, idealWidth: 250)
      .navigationTitle("\(store.selectedGroup?.name ?? "")")
      .navigationSubtitle("Workflows")
      .toolbar(content: {
        WorkflowListToolbar(groupId: groupSelection, workflowsController: store.context.workflows)
      })

      DetailView(context: store.context, workflowController: store.context.workflow)
        .placeholder(if: store.context.workflows.isEmpty,
                     DetailViewPlaceHolder().toolbar(content: {
                      ToolbarItemGroup { Spacer() }
                     })
        )
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
