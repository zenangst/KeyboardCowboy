import Foundation

public protocol GroupsControlling {
  /// Filter groups based on current set of rules.
  /// For more information about rules, check the
  /// implementation of `Rule` value-type.
  ///
  /// - Parameter rule: The rule that the groups should
  ///                   be evaluated against.
  func filterGroups(using rule: Rule) -> [Group]

  func updateGroups(_ groups: [Group])
}

class GroupsController: GroupsControlling {
  var groups: [Group]

  init(groups: [Group]) {
    self.groups = groups
  }

  public func filterGroups(using rule: Rule) -> [Group] {
    groups.filter { group in
      guard let groupRule = group.rule else { return true }

      if !groupRule.applications.compactMap({ $0.bundleIdentifier })
          .allowedAccording(to: rule.applications.compactMap({ $0.bundleIdentifier })) {
        return false
      }

      if !groupRule.days.allowedAccording(to: rule.days) {
        return false
      }

      return true
    }
  }

  public func updateGroups(_ groups: [Group]) {
    self.groups = groups
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
