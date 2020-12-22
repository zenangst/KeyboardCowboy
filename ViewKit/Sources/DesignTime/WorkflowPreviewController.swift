import ModelKit

final class WorkflowPreviewController: ViewController {
  var state = Workflow.empty()
  func perform(_ action: DetailView.Action) {
    switch action {
    case .set(let workflow):
      state = workflow
    }
  }
}
