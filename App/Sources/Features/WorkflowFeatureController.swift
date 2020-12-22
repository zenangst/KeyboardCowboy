import Foundation
import ModelKit
import ViewKit
import SwiftUI

protocol WorkflowFeatureControllerDelegate: AnyObject {
  func workflowFeatureController(_ controller: WorkflowFeatureController, didUpdateWorkflow workflow: Workflow)
}

final class WorkflowFeatureController: ViewController {
  weak var delegate: WorkflowFeatureControllerDelegate?
  @Published var state: Workflow = .empty()

  func perform(_ action: DetailView.Action) {
    switch action {
    case .set(let workflow):
      state = workflow
      delegate?.workflowFeatureController(self, didUpdateWorkflow: workflow)
    }
  }
}
