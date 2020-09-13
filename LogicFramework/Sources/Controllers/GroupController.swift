import Foundation

protocol GroupControlling {
  /// Filter groups based on current set of rules.
  /// For more information about rules, check the
  /// implementation of `Rule` value-type.
  ///
  /// - Parameter rule: The rule that the groups should
  ///                   be evaluated against.
  func filterGroups(using rule: Rule) -> [Group]
}

class GroupController: GroupControlling {
  var groups: [Group]

  init(groups: [Group]) {
    self.groups = groups
  }

  func filterGroups(using rule: Rule) -> [Group] {
    groups.filter { group in
      guard let groupRule = group.rule else { return true }

      if !groupRule.applications.allowedAccording(to: rule.applications) {
        return false
      }

      if !groupRule.days.allowedAccording(to: rule.days) {
        return false
      }

      return true
    }
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
