import Apps
import Bonzai
import Foundation

enum SidebarMapper {
  static func map(_ group: WorkflowGroup, applicationStore: ApplicationStore) -> GroupViewModel {
    let icon: Icon?
    if let rule = group.rule {
      icon = rule.icon(using: applicationStore)
    } else {
      icon = nil
    }
    return group.asViewModel(icon)
  }
}

extension WorkflowGroup {
  func asViewModel(_ icon: Icon?) -> GroupViewModel {
    return GroupViewModel(
      id: id,
      name: name,
      icon: icon,
      color: color,
      symbol: symbol,
      bundleIdentifiers: rule?.allowedBundleIdentifiers ?? [],
      userModes: userModes,
      count: workflows.count,
      isDisabled: isDisabled
    )
  }
}

private extension Rule {
  func icon(using applicationStore: ApplicationStore) -> Icon? {
    if let bundleIdentifier: String = allowedBundleIdentifiers.first,
       let app: Application = applicationStore.application(for: bundleIdentifier)
    {
      return .init(bundleIdentifier: app.bundleIdentifier, path: app.path)
    }
    return nil
  }
}
