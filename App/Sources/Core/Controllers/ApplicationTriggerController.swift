import Apps
import Combine
import Cocoa
import MachPort

final class ApplicationTriggerController: @unchecked Sendable, ApplicationCommandRunnerDelegate {
  private let workflowRunner: WorkflowRunning
  private var activateActions = [String: [ApplicationTriggerWorkflow]]()
  private var bundleIdentifiers = [String]()
  private var closeActions = [String: [ApplicationTriggerWorkflow]]()
  private var frontmostApplicationSubscription: AnyCancellable?
  private var openActions = [String: [ApplicationTriggerWorkflow]]()
  private var runningApplicationsSubscription: AnyCancellable?
  private var workflowGroupsSubscription: AnyCancellable?
  private var resignActions = [String: [ApplicationTriggerWorkflow]]()
  private var previousApplication: UserSpace.Application?

  init(_ workflowRunner: WorkflowRunning) {
    self.workflowRunner = workflowRunner
  }

  func subscribe(to publisher: Published<[UserSpace.Application]>.Publisher) {
    runningApplicationsSubscription = publisher
      .sink { [weak self] bundleIdentifiers in
        guard let self else { return }
        DispatchQueue.main.async {
          self.process(bundleIdentifiers.map { $0.bundleIdentifier }) }
      }
  }

  func subscribe(to publisher: Published<UserSpace.Application>.Publisher) {
    frontmostApplicationSubscription = publisher
      .sink { [weak self] frontmostApplication in
        guard let self else { return }
        DispatchQueue.main.async {
          self.process(frontmostApplication)
        }
      }
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    workflowGroupsSubscription = publisher.sink { [weak self] groups in
      guard let self else { return }
      DispatchQueue.main.async {
        self.receive(groups)
      }
    }
  }

  // MARK: Private methods

  @MainActor
  private func receive(_ groups: [WorkflowGroup]) {
    self.activateActions.removeAll()
    self.resignActions.removeAll()
    self.openActions.removeAll()
    self.closeActions.removeAll()
    self.activateActions.removeAll()

    let triggerWorkflows: [ApplicationTriggerWorkflow] = groups
      .filter { !$0.isDisabled }
      .flatMap { group in
        group.workflows.map({ ApplicationTriggerWorkflow(userModes: Set(group.userModes.map(\.asEnabled)),
                                                         workflow: $0) })
      }

    triggerWorkflows.forEach { workflow in
      guard workflow.isEnabled else { return }
      switch workflow.trigger {
      case .application(let triggers):
        for trigger in triggers {
          if trigger.contexts.contains(.closed) {
            self.closeActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }

          if trigger.contexts.contains(.launched) {
            self.openActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }

          if trigger.contexts.contains(.frontMost) {
            self.activateActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }

          if trigger.contexts.contains(.resignFrontMost) {
            self.resignActions[trigger.application.bundleIdentifier, default: []].append(workflow)
          }
        }
      case .keyboardShortcuts, .snippet, .modifier, .none:
        return
      }
    }
  }

  @MainActor
  private func process(_ frontmostApplication: UserSpace.Application) {
    if let anyAppTriggerWorkflows = self.activateActions[Application.anyAppBundleIdentifier()] {
      runTriggerWorkflows(anyAppTriggerWorkflows)
    }

    if let triggerWorkflows = self.activateActions[frontmostApplication.bundleIdentifier] {
      runTriggerWorkflows(triggerWorkflows)
    }

    if let previousApplication, let triggerWorkflows = self.resignActions[previousApplication.bundleIdentifier] {
      runTriggerWorkflows(triggerWorkflows)
    }
    previousApplication = frontmostApplication
  }

  @MainActor
  private func process(_ bundleIdentifiers: [String]) {
    let difference = bundleIdentifiers.difference(from: self.bundleIdentifiers)

    if difference.isEmpty { return }

    var triggerWorkflows = [ApplicationTriggerWorkflow]()
    for change in difference {
      switch change {
      case .insert(_, let bundleIdentifier, _):
        if let openActions = openActions[bundleIdentifier] {
          triggerWorkflows.append(contentsOf: openActions)
        }
      case .remove(_, let bundleIdentifier, _):
        if let closeActions = closeActions[bundleIdentifier] {
          triggerWorkflows.append(contentsOf: closeActions)
        }
      }
    }

    runTriggerWorkflows(triggerWorkflows)

    self.bundleIdentifiers = bundleIdentifiers
  }

  @MainActor
  private func runTriggerWorkflows(_ triggerWorkflows: [ApplicationTriggerWorkflow]) {
    let userModes = Set(UserSpace.shared.userModes.filter(\.isEnabled))
    triggerWorkflows
      .filter {
        if $0.userModes.isEmpty {
          true
        } else {
          $0.userModes.isSubset(of: userModes)
        }
      }
      .map(\.workflow)
      .forEach(workflowRunner.runCommands(in:))
  }

  // MARK: ApplicationCommandRunnerDelegate

  func applicationCommandRunnerWillRunApplicationCommand(_ command: ApplicationCommand) {
    switch command.action {
    case .open:
      if let previousApplication, let triggerWorkflows = self.resignActions[previousApplication.bundleIdentifier] {
        runTriggerWorkflows(triggerWorkflows)
      }
    default:
      break
    }
  }
}

private struct ApplicationTriggerWorkflow {
  let userModes: Set<UserMode>
  let workflow: Workflow

  var isEnabled: Bool { workflow.isEnabled }
  var trigger: Workflow.Trigger? { workflow.trigger }
}

extension Application {
  static func anyAppBundleIdentifier() -> String {
    "*.*.*"
  }

  static func currentAppBundleIdentifier() -> String {
    "*.*.current"
  }

  static func anyApplication() -> Application {
    Application(
      bundleIdentifier: anyAppBundleIdentifier(),
      bundleName: "Any Application",
      displayName: "Any Application",
      path: "Any Application"
    )
  }

  static func currentApplication() -> Application {
    Application(
      bundleIdentifier: currentAppBundleIdentifier(),
      bundleName: "Current Application",
      displayName: "Current Application",
      path: "Current Application"
    )
  }
}
