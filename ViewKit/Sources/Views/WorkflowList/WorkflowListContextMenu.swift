import SwiftUI
import ModelKit

struct WorkflowListContextMenu: View {
  let workflowController: WorkflowController
  let workflow: Workflow
  @AppStorage("groupSelection") var groupSelection: String?

  var body: some View {
    Button("Duplicate", action: { workflowController.perform(.duplicate(workflow, groupId: groupSelection)) })
    Button("Delete", action: { workflowController.perform(.delete(workflow)) })
  }
}
