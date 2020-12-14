import ModelKit

final class WorkflowPreviewController: ViewController {
  var state: Workflow = ModelKit.Workflow.empty()
  func perform(_ action: WorkflowList.Action) {
    switch action {
    case .set(let workflow):
      state = workflow
    default:
      break
    }
  }
}
