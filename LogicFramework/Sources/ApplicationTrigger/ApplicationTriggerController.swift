import Cocoa
import Combine
import ModelKit
import Foundation

private struct ApplicationTriggerContainer: Hashable {
  let trigger: ApplicationTrigger
  var workflow: Workflow
}

public protocol ApplicationTriggerControlling: AnyObject {
  init(commandController: CommandControlling,
       workspace: NSWorkspace)

  func recieve(_ groups: [Group])
}

public class ApplicationTriggerController: ApplicationTriggerControlling {
  private var commandController: CommandControlling
  private var subscriptions: [AnyCancellable] = .init()
  private var workflows: [Workflow] = .init()
  private var storage: [String: [ApplicationTriggerContainer]] = .init()
  private var tagged: [ApplicationTrigger.Context: Set<ApplicationTriggerContainer>] = .init()

  required public init(commandController: CommandControlling,
                       workspace: NSWorkspace) {
    self.commandController = commandController
    workspace
      .publisher(for: \.runningApplications)
      .sink { runningsApplications in
        guard !self.storage.isEmpty else { return }
        let bundleIdentifiers = runningsApplications.compactMap({ $0.bundleIdentifier })
        self.process(bundleIdentifiers)
      }
      .store(in: &subscriptions)

    workspace.publisher(for: \.frontmostApplication)
      .sink { runningApplication in
        guard let bundleIdentifier = runningApplication?.bundleIdentifier,
              let storage = self.storage[bundleIdentifier] else { return }

        let matches: [ApplicationTriggerContainer] = storage.filter({
          $0.trigger.contexts.contains(.frontMost)
        })

        for match in matches {
          commandController.run(match.workflow.commands)
        }
      }
      .store(in: &subscriptions)
  }

  // MARK: Public methods

  public func recieve(_ groups: [Group]) {
    storage.removeAll()
    let workflows = groups.flatMap({ $0.workflows })
    for workflow in workflows where workflow.isEnabled {
      switch workflow.trigger {
      case .application(let triggers):
        for trigger in triggers {
          let container = ApplicationTriggerContainer(trigger: trigger,
                                                      workflow: workflow)
          let values: [ApplicationTriggerContainer]
          if var previousValues = storage[trigger.application.bundleIdentifier] {
            previousValues.append(container)
            values = previousValues
          } else {
            values = [container]
          }

          storage[trigger.application.bundleIdentifier] = values
        }
      case .keyboardShortcuts, .none:
        break
      }
    }
  }

  // MARK: Private methods

  private func process(_ bundleIdentifiers: [String]) {
    for bundleIdentifier in bundleIdentifiers {
      guard let containers = storage[bundleIdentifier] else { continue }

      var launched: Set<ApplicationTriggerContainer> = tagged[.launched] ?? []
      for container in containers {
        if !launched.contains(container),
           container.trigger.contexts.contains(.launched) {
          launched.insert(container)
          commandController.run(container.workflow.commands)
          self.tagged[.launched] = launched
        }
      }
    }

    if var launched = tagged[.launched] {
      for container in launched where !bundleIdentifiers.contains(container.trigger.application.bundleIdentifier) {
        defer {
          launched.remove(container)
          self.tagged[.launched] = launched
        }

        guard let containers = storage[container.trigger.application.bundleIdentifier] else { continue }

        for container in containers where container.trigger.contexts.contains(.closed) {
          commandController.run(container.workflow.commands)
        }
      }
    }
  }
}
