import Foundation

class GroupController {
  var groups: [Group]

  init(groups: [Group]) {
    self.groups = groups
  }

  func filterGroups(using rule: Rule) -> [Group] {
    groups.filter { group in
      guard let groupRule = group.rule else { return true }

      if !groupRule.applications.allowedAccording(rule.applications) {
        return false
      }

      if !groupRule.days.allowedAccording(rule.days) {
        return false
      }

      return true
    }
  }
}

private extension Collection where Iterator.Element: Hashable {
  func allowedAccording(_ rhs: [Element]) -> Bool {
    if isEmpty { return true }

    let lhs = Set(self)
    let rhs = Set(rhs)
    return !lhs.isDisjoint(with: rhs)
  }
}
