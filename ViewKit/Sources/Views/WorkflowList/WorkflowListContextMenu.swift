import SwiftUI
import ModelKit

struct WorkflowListContextMenu: View {
  let workflowsController: WorkflowsController
  let workflow: Workflow
  @AppStorage("groupSelection") var groupSelection: String?

  var body: some View {
    Button("Duplicate", action: { workflowsController.perform(.duplicate(workflow, groupId: groupSelection)) })
    Button("Delete", action: { workflowsController.perform(.delete(workflow)) })
  }
}
