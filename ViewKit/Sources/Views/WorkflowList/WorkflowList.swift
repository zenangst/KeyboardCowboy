import SwiftUI

public struct WorkflowList: View {
  public enum Action {
    case createWorkflow
    case updateWorkflow(WorkflowViewModel)
    case deleteWorkflow(WorkflowViewModel)
    case moveWorkflow(from: Int, to: Int)
  }

  static let idealWidth: CGFloat = 300
  @EnvironmentObject var userSelection: UserSelection
  @Binding var group: GroupViewModel
  let workflowController: WorkflowController

  init(group: Binding<GroupViewModel>, workflowController: WorkflowController) {
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
    List(selection: Binding(get: {
      userSelection.workflow
    }, set: { workflow in
      userSelection.workflow = workflow
    })) {
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
          workflowController.perform(.moveWorkflow(from: i, to: newOffset))
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

private final class WorkflowPreviewController: ViewController {
  let state = ModelFactory().workflowList().first
  func perform(_ action: WorkflowList.Action) {}
}
