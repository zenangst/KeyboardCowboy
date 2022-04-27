import Apps
import Combine
import Foundation
import AppKit

final class WorkflowEngine {
  private var subscriptions: Set<AnyCancellable> = .init()
  private let keyboardEngine = KeyboardStrokeEngine()

  init(applicationStore: ApplicationStore,
       configStore: ConfigurationStore,
       workspace: NSWorkspace = .shared) {
    configStore.$selectedConfiguration
      .combineLatest(
        applicationStore.$applications,
        workspace
          .publisher(for: \.frontmostApplication)
          .compactMap{ $0 }
          .eraseToAnyPublisher()
      )
      .filter { configuration, apps, _ in
        !configuration.groups.isEmpty &&
        !apps.isEmpty
      }
      .sink { [weak self] configuration, apps, frontApp in
        self?.reload(configuration, with: apps, frontApp: frontApp)
      }
      .store(in: &subscriptions)
  }

  func reload(_ configuration: KeyboardCowboyConfiguration,
              with applications: [Application],
              frontApp: NSRunningApplication) {
    var rule = Rule()

    rule.bundleIdentifiers = applications
      .compactMap { $0.bundleIdentifier }
      .filter { $0 == frontApp.bundleIdentifier }

    let groups = configuration.groups.filter { group in
      guard let groupRule = group.rule else { return true }

      if !groupRule.bundleIdentifiers.allowedAccording(to: rule.bundleIdentifiers) {
        return false
      }

      if !groupRule.days.allowedAccording(to: rule.days) {
        return false
      }

      return true
    }

    let workflows = groups
      .flatMap { $0.workflows }
      .filter { $0.isEnabled }

    keyboardEngine.activate(workflows)
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
