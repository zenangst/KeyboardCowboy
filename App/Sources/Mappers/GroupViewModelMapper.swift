import Foundation
import LogicFramework
import ViewKit

protocol GroupViewModelMapping {
  func map(_ models: [Group]) -> [GroupViewModel]
  func map(_ model: Group) -> GroupViewModel
}

class GroupViewModelMapper: GroupViewModelMapping {
  let workflowMapper: WorkflowViewModelMapping

  init(workflowMapper: WorkflowViewModelMapping) {
    self.workflowMapper = workflowMapper
  }

  func map(_ models: [Group]) -> [GroupViewModel] {
    models.compactMap(map(_:))
  }

  func map(_ model: Group) -> GroupViewModel {
    .init(id: model.id,
          name: model.name,
          color: model.color,
          workflows: workflowMapper.map(model.workflows))
  }
}
