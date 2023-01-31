import Apps
import Foundation

final class SidebarMapper {
  static func map(_ group: WorkflowGroup, applicationStore: ApplicationStore) -> GroupViewModel {
    let iconPath: String?
    if let rule = group.rule {
      iconPath = rule.iconPath(using: applicationStore)
    } else {
      iconPath = nil
    }
    return group.asViewModel(iconPath)
  }
}

extension WorkflowGroup {
  func asViewModel(_ iconPath: String?) -> GroupViewModel {
    GroupViewModel(
      id: id,
      name: name,
      iconPath: iconPath,
      color: color,
      symbol: symbol,
      count: workflows.count)
  }
}

private extension Rule {
  func iconPath(using applicationStore: ApplicationStore) -> String? {
    if let bundleIdentifier: String = bundleIdentifiers.first,
       let app: Application = applicationStore.application(for: bundleIdentifier) {
      return app.path
    }
    return nil
  }
}
