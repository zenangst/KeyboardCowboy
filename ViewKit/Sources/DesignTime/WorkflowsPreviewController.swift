import ModelKit

final class WorkflowsPreviewController: ViewController {
  var state: [Workflow] = ModelFactory().workflowList()
  func perform(_ action: WorkflowList.Action) {}
}
