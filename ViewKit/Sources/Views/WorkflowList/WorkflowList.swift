import SwiftUI
import ModelKit

public struct WorkflowList: View {
  public enum Action {
    case createWorkflow
    case updateWorkflow(Workflow)
    case deleteWorkflow(Workflow)
    case moveWorkflow(Workflow, to: Int)
  }

  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  @Binding var group: ModelKit.Group
  let workflowController: WorkflowController

  init(group: Binding<ModelKit.Group>, workflowController: WorkflowController) {
    self._group = group
    self.workflowController = workflowController
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      list.listStyle(PlainListStyle())
      addButton.padding(8)
    }
  }
}

private extension WorkflowList {
  var list: some View {
    List(selection: $userSelection.workflow) {
      ForEach(group.workflows) { workflow in
        WorkflowListCell(workflow: workflow)
          .contextMenu {
            Button("Delete") {
              workflowController.perform(.deleteWorkflow(workflow))
            }
          }
          .frame(height: 48)
          .tag(workflow)
      }.onMove(perform: { indices, newOffset in
        for i in indices {
          let workflow = group.workflows[i]
          workflowController.perform(.moveWorkflow(workflow, to: newOffset))
        }
      }).onDelete(perform: { indexSet in
        for index in indexSet {
          let workflow = group.workflows[index]
          workflowController.perform(.deleteWorkflow(workflow))
        }
      })
    }
  }

  var addButton: some View {
    HStack(spacing: 4) {
      RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
        .onTapGesture {
          workflowController.action(.createWorkflow)()
        }
      Button("Add Workflow", action: {
        workflowController.action(.createWorkflow)()
      })
      .buttonStyle(PlainButtonStyle())
    }
  }
}

// MARK: - Previews

struct WorkflowList_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    WorkflowList(group: .constant(ModelFactory().groupList().first!),
                 workflowController: WorkflowPreviewController().erase())
      .frame(width: WorkflowList.idealWidth, height: 360)
      .environmentObject(UserSelection())
  }
}
