import LogicFramework
import ModelKit

class WorkflowControllerMock: WorkflowControlling {
  var workflows = [Workflow]()
  var filteredWorkflows = [Workflow]()

  func filterWorkflows(from groups: [Group], keyboardShortcuts: [KeyboardShortcut]) -> [Workflow] {
    filteredWorkflows
  }
}
