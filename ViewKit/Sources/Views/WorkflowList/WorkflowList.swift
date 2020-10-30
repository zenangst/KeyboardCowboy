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
  let workflowController: WorkflowController
  @State private var selection: Workflow?

  public var body: some View {
    List {
      ForEach(group.workflows) { workflow in
        NavigationLink(
          destination: factory.workflowDetail(workflow, group: group),
          tag: workflow,
          selection: $userSelection.workflow,
          label: {
            WorkflowListCell(workflow: workflow)
              .contextMenu {
                Button("Delete") {
                  workflowController.perform(.deleteWorkflow(workflow, in: group))
                }
              }
              .frame(height: 48)
          })
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
