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
  func group(for workflow: Workflow) -> Group?
  func workflow(for command: Command) -> Workflow?
  func workflow(for keyboardShortcut: KeyboardShortcut) -> Workflow?
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

  public func group(for workflow: Workflow) -> Group? {
    groups.first(where: { $0.workflows.containsElement(workflow) })
  }

  public func workflow(for command: Command) -> Workflow? {
    groups
      .flatMap { $0.workflows }
      .first(where: { $0.commands.containsElement(command) })
  }

  public func workflow(for keyboardShortcut: KeyboardShortcut) -> Workflow? {
    groups
      .flatMap { $0.workflows }
      .first(where: { $0.keyboardShortcuts.containsElement(keyboardShortcut) })
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
