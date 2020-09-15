import Foundation

public protocol WorkflowControlling {
  /// Filter workflows based on a collection of combinations.
  ///
  /// Matching is done by concatinating combinations and verifying that the
  /// the workflows combination starts with the same combination.
  /// If the combination count and the workflows combination count are equal,
  /// this would mean that we found a unique combination.
  ///
  /// By design, only unique combinations should be allowed to be executed,
  /// meaning that the combinations on both left- & right-side needs to be
  /// equal. There is however no restriction on how many workflows are allowed
  /// to be unique. Unique here only means that the workflow is a perfect match
  /// not that the result type of the methods is a `Set<Workflow>`.
  ///
  /// - Parameters:
  ///   - groups: The groups that are eligable for workflow filtering
  ///   - keyboardShortcuts: The combination that should be used inside the algorithm
  ///                        for figuring out uniqueness.
  func filterWorkflows(from groups: [Group], keyboardShortcuts: [KeyboardShortcut]) -> [Workflow]
}

public class WorkflowController: WorkflowControlling {
  public init() {}

  public func filterWorkflows(from groups: [Group], keyboardShortcuts: [KeyboardShortcut]) -> [Workflow] {
    groups.flatMap { $0.workflows }
      .filter {
        if keyboardShortcuts.count < $0.keyboardShortcuts.count {
          let lhs = $0.keyboardShortcuts.compactMap { $0.rawValue }.joined()
          let rhs = keyboardShortcuts.compactMap { $0.rawValue }.joined()
          return lhs.starts(with: rhs)
        } else {
          return $0.keyboardShortcuts == keyboardShortcuts
        }
      }
  }
}
