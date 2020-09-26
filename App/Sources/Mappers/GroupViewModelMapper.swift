import Foundation
import LogicFramework
import ViewKit

protocol GroupViewModelMapping {
  func map(_ models: [Group]) -> [GroupViewModel]
}

class GroupViewModelMapper: GroupViewModelMapping {
  let workflowMapper: WorkflowViewModelMapping

  init(workflowMapper: WorkflowViewModelMapping) {
    self.workflowMapper = workflowMapper
  }

  func map(_ models: [Group]) -> [GroupViewModel] {
    models.compactMap {
      .init(id: $0.id, name: $0.name, workflows: workflowMapper.map($0.workflows))
    }
  }
}
