import Foundation

class GroupController {
  var groups: [Group]

  init(groups: [Group]) {
    self.groups = groups
  }

  func filterGroups(using rules: [Rule]) -> [Group] {
    var validGroups = groups

    for rule in rules {
      switch rule {
      case .application:
        validGroups = validGroups.filter({ group in
          let applicationRules = group.rules.filter({
            if case .application = $0 { return true }
            return false
          })
          return applicationRules.isEmpty || applicationRules.contains(rule)
        })
      case .days(let value):
        validGroups = validGroups.filter({ group in
          let dayRules = group.rules.filter({
            if case .days = $0 {
              return true
            }
            return false
          })

          let dayFilter = Set(value)
          var days = [Rule.Day]()
          for rule in dayRules {
            if case .days(let filterDays) = rule {
              days.append(contentsOf: filterDays)
            }
          }
          if days.isEmpty { return true }

          return !dayFilter.isDisjoint(with: days)
        })
      }
    }

    return validGroups
  }
}
