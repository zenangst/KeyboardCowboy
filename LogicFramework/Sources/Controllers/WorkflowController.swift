import Foundation

class WorkflowController {
  func filterWorkflows(from groups: [Group], combinations: [Combination]) -> [Workflow] {
    groups.flatMap { $0.workflows }
      .filter {
        if combinations.count < $0.combinations.count {
          let lhs = $0.combinations.compactMap { $0.input }.joined()
          let rhs = combinations.compactMap { $0.input }.joined()
          return lhs.starts(with: rhs)
        } else {
          return $0.combinations == combinations
        }
      }
  }
}
