import SwiftUI
import ModelKit
import Introspect

public struct WorkflowList: View {
  public enum Action {
    case createWorkflow(in: ModelKit.Group)
    case updateWorkflow(Workflow, in: ModelKit.Group)
    case deleteWorkflow(Workflow, in: ModelKit.Group)
    case moveWorkflow(Workflow, to: Int, in: ModelKit.Group)
  }
  
  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  let factory: ViewFactory
  let group: ModelKit.Group
  let searchController: SearchController
  let workflowController: WorkflowController
  @State private var selection: Workflow?
  
  public var body: some View {
    if !userSelection.searchQuery.isEmpty {
      SearchView(searchController: searchController)
    } else {
      List {
        ForEach(group.workflows, id: \.id) { workflow in
          
          NavigationLink(destination: factory.workflowDetail(workflow, group: group),
                         tag: workflow, selection: $userSelection.workflow) {
            WorkflowListCell(workflow: workflow).frame(height: 40)
          }.contextMenu {
            Button("Delete") {
              workflowController.perform(.deleteWorkflow(workflow, in: group))
            }
          }
        }.onMove(perform: { indices, newOffset in
          for i in indices {
            let workflow = group.workflows[i]
            workflowController.perform(.moveWorkflow(workflow, to: newOffset, in: group))
          }
        }).onDelete(perform: { indexSet in
          for index in indexSet {
            let workflow = group.workflows[index]
            workflowController.perform(.deleteWorkflow(workflow, in: group))
          }
        })
      }
      .frame(minWidth: 275)
      .id(group.id)
      .introspectTableView(customize: {
        $0.allowsEmptySelection = false
      })
      .navigationTitle("\(group.name)")
      .navigationSubtitle("Workflows: \(group.workflows.count)")
      .environment(\.defaultMinListRowHeight, 1)
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }
  
  static var testPreview: some View {
    DesignTimeFactory().workflowList(group: ModelFactory().groupList().first!)
      .environmentObject(UserSelection())
  }
}
