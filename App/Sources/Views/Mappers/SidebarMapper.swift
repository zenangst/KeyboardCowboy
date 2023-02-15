import Apps
import Foundation

final class SidebarMapper {
  static func map(_ group: WorkflowGroup, applicationStore: ApplicationStore) -> GroupViewModel {
    let icon: IconViewModel?
    if let rule = group.rule {
      icon = rule.icon(using: applicationStore)
    } else {
      icon = nil
    }
    return group.asViewModel(icon)
  }
}

extension WorkflowGroup {
  func asViewModel(_ icon: IconViewModel?) -> GroupViewModel {
    GroupViewModel(
      id: id,
      name: name,
      icon: icon,
      color: color,
      symbol: symbol,
      count: workflows.count)
  }
}

private extension Rule {
  func icon(using applicationStore: ApplicationStore) -> IconViewModel? {
    if let bundleIdentifier: String = bundleIdentifiers.first,
       let app: Application = applicationStore.application(for: bundleIdentifier) {
      return .init(bundleIdentifier: app.bundleIdentifier, path: app.path)
    }
    return nil
  }
}
