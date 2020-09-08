import Foundation

class GroupController {
  var groups: [Group]

  init(groups: [Group]) {
    self.groups = groups
  }

  func filterGroups(using rule: Rule) -> [Group] {
    var validGroups = [Group]()
    for group in groups {
      guard let groupRule = group.rule else {
        validGroups.append(group)
        continue
      }

      if !groupRule.applications.allowedAccording(rule.applications) {
        continue
      }

      if !groupRule.days.allowedAccording(rule.days) {
        continue
      }

      validGroups.append(group)
    }

    return validGroups
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
