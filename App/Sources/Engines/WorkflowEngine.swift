import Apps
import Combine
import Foundation
import AppKit
import os

final class WorkflowEngine {
  private let commandEngine: CommandEngine

  @Published private(set) var activeWorkflows: [Workflow] = .init()
  @Published private(set) var sequence: [KeyShortcut] = .init()

  private var resetInterval: TimeInterval = 1.0
  private var sessionWorkflows: [Workflow] = .init()
  private var subscriptions: Set<AnyCancellable> = .init()

  private var timer: Timer?

  init(applicationStore: ApplicationStore,
       commandEngine: CommandEngine,
       configStore: ConfigurationStore,
       workspace: NSWorkspace = .shared) {
    self.commandEngine = commandEngine
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
        guard let self = self else { return }
        self.reload(configuration, with: apps, frontApp: frontApp)
      }
      .store(in: &subscriptions)
  }

  func subscribe(to publisher: Published<MachPortEngine.Event?>.Publisher) {
    publisher
      .compactMap { $0 }
      .sink { [weak self] event in
      self?.respond(to: event)
    }.store(in: &subscriptions)
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

    activate(workflows)
  }

  func activate(_ newWorkflows: [Workflow]) {
    sequence = []
    activeWorkflows = newWorkflows
    sessionWorkflows = newWorkflows
  }

  func reset() {
    sequence = []
    sessionWorkflows = activeWorkflows
  }

  func respond(to event: MachPortEngine.Event) {
    if event.kind != .keyDown {
      self.reset()
      return
    }

    sequence.append(event.keyboardShortcut)

    var shortcutsToActivate = Set<KeyShortcut>()
    var workflowsToActivate = Set<Workflow>()

    let workflows = sessionWorkflows.filter { workflow in
      guard case let .keyboardShortcuts(shortcuts) = workflow.trigger else { return false }

      let lhs = sequence.sequenceValue
      let rhs = shortcuts.sequenceValue

      if rhs.isEmpty { return false }

      if sequence.count < shortcuts.count {
        return rhs.starts(with: lhs)
      } else {
        let perfectMatch = lhs == rhs
        if perfectMatch {
          workflowsToActivate.insert(workflow)
        }
        return perfectMatch
      }
    }

    for workflow in workflows where workflow.isEnabled {
      guard case let .keyboardShortcuts(shortcuts) = workflow.trigger,
            shortcuts.count >= sequence.count
            else { continue }

      guard let validShortcut = shortcuts[sequence.count..<shortcuts.count].first
      else { continue }
      workflowsToActivate.insert(workflow)
      shortcutsToActivate.insert(validShortcut)
    }

    if shortcutsToActivate.isEmpty {
      workflowsToActivate.forEach { workflow in
        let commands = workflow.commands.filter(\.isEnabled)
        commandEngine.serialRun(commands)
      }
      sequence = []
      sessionWorkflows = activeWorkflows
      timer?.invalidate()
      reset()
    } else {
      sessionWorkflows = Array(workflowsToActivate)
    }

    timer?.invalidate()
    let timer = Timer(timeInterval: resetInterval, repeats: false) { [weak self] _ in
      self?.reset()
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
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

private extension Collection where Element == KeyShortcut {
  var sequenceValue: String {
    compactMap { $0.stringValue }.joined()
  }
}
