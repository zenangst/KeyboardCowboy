import Foundation

class ViewModelMapperFactory {
  func groupMapper() -> GroupViewModelMapping {
    GroupViewModelMapper(workflowMapper: workflowMapper())
  }

  func workflowMapper() -> WorkflowViewModelMapping {
    WorkflowViewModelMapper(commandMapper: commandMapper(),
                            combinationMapper: combinationMapper())
  }

  func commandMapper() -> CommandViewModelMapping {
    CommandViewModelMapper()
  }

  func combinationMapper() -> CombinationViewModelMapping {
    CombinationViewModelMapper()
  }
}
