import Foundation
import LogicFramework
import ViewKit

class GroupViewModelMapper {
  let workflowMapper = WorkflowViewModelMapper()

  func map(_ models: [Group]) -> [GroupViewModel] {
    models.compactMap {
      .init(name: $0.name, workflows: workflowMapper.map($0.workflows))
    }
  }
}
