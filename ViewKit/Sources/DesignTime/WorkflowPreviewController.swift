import ModelKit

final class WorkflowPreviewController: ViewController {
  let state = ModelFactory().workflowList().first
  func perform(_ action: WorkflowList.Action) {}
}

