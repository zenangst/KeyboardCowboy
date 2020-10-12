import Foundation
import ModelKit

public protocol GroupsControlling {
  var delegate: GroupsControllingDelegate? { get set }
  var groups: [Group] { get }

  /// Filter groups based on current set of rules.
  /// For more information about rules, check the
  /// implementation of `Rule` value-type.
  ///
  /// - Parameter rule: The rule that the groups should
  ///                   be evaluated against.
  func filterGroups(using rule: Rule) -> [Group]
  func reloadGroups(_ groups: [Group])
  func groupContext(withIdentifier id: String) -> GroupContext?
  func workflowContext(workflowId: String) -> WorkflowContext?
}

public protocol GroupsControllingDelegate: AnyObject {
  func groupsController(_ controller: GroupsControlling, didReloadGroups groups: [Group])
}

class GroupsController: GroupsControlling {
  weak var delegate: GroupsControllingDelegate?
  var groups: [Group]

  init(groups: [Group]) {
    self.groups = groups
  }

  public func filterGroups(using rule: Rule) -> [Group] {
    groups.filter { group in
      guard let groupRule = group.rule else { return true }

      if !groupRule.bundleIdentifiers.allowedAccording(to: rule.bundleIdentifiers) {
        return false
      }

      if !groupRule.days.allowedAccording(to: rule.days) {
        return false
      }

      return true
    }
  }

  public func reloadGroups(_ groups: [Group]) {
    self.groups = groups
    delegate?.groupsController(self, didReloadGroups: groups)
  }

  public func groupContext(withIdentifier id: String) -> GroupContext? {
    for (offset, group) in groups.enumerated() where group.id == id {
      return GroupContext(index: offset, model: group)
    }
    return nil
  }

  public func workflowContext(workflowId: String) -> WorkflowContext? {
    for (gOffset, group) in groups.enumerated() {
      for (wOffset, workflow) in group.workflows.enumerated() where workflow.id == workflowId {
        return WorkflowContext(
          index: wOffset, groupContext: GroupContext(index: gOffset, model: group),
          model: workflow)
      }
    }

    return nil
  }
}

private extension Collection where Iterator.Element: Hashable {
  func allowedAccording(to rhs: [Element]) -> Bool {
    if isEmpty { return true }

    let lhs = Set(self)
    let rhs = Set(rhs)

    return !lhs.isDisjoint(with: rhs)
  }
}

public struct GroupContext {
  public let index: Int
  public let model: Group

  public init(index: Int, model: Group) {
    self.index = index
    self.model = model
  }
}

public struct WorkflowContext {
  public let index: Int
  public let groupContext: GroupContext
  public let model: Workflow

  public init(index: Int, groupContext: GroupContext, model: Workflow) {
    self.index = index
    self.groupContext = groupContext
    self.model = model
  }
}
