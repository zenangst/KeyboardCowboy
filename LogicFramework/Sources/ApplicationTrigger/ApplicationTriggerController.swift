import Cocoa
import Combine
import ModelKit
import Foundation

struct ApplicationTriggerContainer: Hashable {
  let trigger: ApplicationTrigger
  var workflow: Workflow
}

public protocol ApplicationTriggerControlling: AnyObject {
  init(commandController: CommandControlling,
       workspace: NSWorkspace,
       runningTests: Bool)

  func recieve(_ groups: [Group])
}

public class ApplicationTriggerController: ApplicationTriggerControlling {
  private var bundleIdentifiers = [String]()
  private var commandController: CommandControlling
  private var subscriptions: [AnyCancellable] = .init()

  private(set) var openActions = [String: [Workflow]]()
  private(set) var activateActions = [String: [Workflow]]()
  private(set) var closeActions = [String: [Workflow]]()

  required public init(commandController: CommandControlling,
                       workspace: NSWorkspace,
                       runningTests: Bool = false) {
    self.commandController = commandController

    guard !runningTests else { return }

    workspace
      .publisher(for: \.runningApplications)
      .sink { runningsApplications in
        let bundleIdentifiers = runningsApplications.compactMap({ $0.bundleIdentifier })
        self.process(bundleIdentifiers)
      }
      .store(in: &subscriptions)

    workspace.publisher(for: \.frontmostApplication)
      .sink { runningApplication in
        guard let runningApplication = runningApplication else {
          return
        }

        self.process(runningApplication)
      }
      .store(in: &subscriptions)
  }

  // MARK: Public methods

  public func recieve(_ groups: [Group]) {
    let workflows = groups.flatMap({ $0.workflows })
    for workflow in workflows where workflow.isEnabled {
      switch workflow.trigger {
      case .application(let triggers):
        for trigger in triggers {
          if trigger.contexts.contains(.closed) {
            var closeActions = self.closeActions[trigger.application.bundleIdentifier] ?? []
            closeActions.append(workflow)
            self.closeActions[trigger.application.bundleIdentifier] = closeActions
          }

          if trigger.contexts.contains(.launched) {
            var openActions = self.openActions[trigger.application.bundleIdentifier] ?? []
            openActions.append(workflow)
            self.openActions[trigger.application.bundleIdentifier] = openActions
          }

          if trigger.contexts.contains(.frontMost) {
            var activateActions = self.activateActions[trigger.application.bundleIdentifier] ?? []
            activateActions.append(workflow)
            self.activateActions[trigger.application.bundleIdentifier] = activateActions
          }
        }
      case .keyboardShortcuts, .none:
        break
      }
    }
  }

  // MARK: Internal methods

  func process(_ frontMostApplication: RunningApplication) {
    guard let bundleIdentifier = frontMostApplication.bundleIdentifier,
          let workflows = self.activateActions[bundleIdentifier] else { return }

    for workflow in workflows {
      commandController.run(workflow.commands)
    }
  }

  func process(_ bundleIdentifiers: [String]) {
    let difference = bundleIdentifiers.difference(from: self.bundleIdentifiers)

    if difference.isEmpty { return }

    var workflows = [Workflow]()
    for change in difference {
      switch change {
      case .insert(_, let bundleIdentifier, _):
        workflows.append(contentsOf: openActions[bundleIdentifier] ?? [])
      case .remove(_, let bundleIdentifier, _):
        workflows.append(contentsOf: closeActions[bundleIdentifier] ?? [])
      }
    }

    for workflow in workflows {
      commandController.run(workflow.commands)
    }

    self.bundleIdentifiers = bundleIdentifiers
  }
}
