import Combine
import Foundation
import MachPort

final class SnippetController: @unchecked Sendable {
  private var currentSnippet: String = ""
  private var snippets: Set<String> = []
  private var snippetsStorage = [String: [Workflow]]()
  private var timeout: Timer?
  private var machPortEventSubscription: AnyCancellable?
  private var workflowGroupsSubscription: AnyCancellable?

  private let commandRunner: CommandRunning
  private let keyboardShortcutsController: KeyboardShortcutsController
  private let store: KeyCodesStore
  private let specialKeys: [Int]

  init(commandRunner: CommandRunning,
       keyboardShortcutsController: KeyboardShortcutsController,
       store: KeyCodesStore) {
    self.commandRunner = commandRunner
    self.keyboardShortcutsController = keyboardShortcutsController
    self.store = store
    self.specialKeys = Array(store.specialKeys().keys)
  }

  func subscribe(to publisher: Published<[WorkflowGroup]>.Publisher) {
    workflowGroupsSubscription = publisher.sink { [weak self] in
      self?.receiveGroups($0)
    }
  }

  func subscribe(to publisher: Published<MachPortEvent?>.Publisher) {
    machPortEventSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] machPortEvent in
      self?.receiveMachPortEvent(machPortEvent)
    }
  }

  // MARK: Private methods

  private func receiveMachPortEvent(_ machPortEvent: MachPortEvent) {
    guard machPortEvent.type == .keyUp else { return }
    guard let shortcut = MachPortKeyboardShortcut(machPortEvent, specialKeys: specialKeys, store: store) else {
      return
    }
    let keyboardShortcut: KeyShortcut = shortcut.original

    currentSnippet = currentSnippet + keyboardShortcut.key

    timeout?.invalidate()
    timeout = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { [weak self] timer in
      guard let self else { return }
      currentSnippet = ""
      timer.invalidate()
    })

    if snippets.contains(currentSnippet) {
      guard let workflows = snippetsStorage[currentSnippet] else { return }
      for workflow in workflows {
        runCommands(in: workflow)
      }
      currentSnippet = ""
      timeout?.invalidate()
    }
  }

  private func receiveGroups(_ groups: [WorkflowGroup]) {
    self.snippetsStorage = [:]
    self.snippets = []

    let workflows = groups.flatMap { $0.workflows }

    for workflow in workflows {
      guard workflow.isEnabled else { continue }
        if let trigger = workflow.trigger {
            switch trigger {
            case .snippet(let trigger):
              if let existingWorkflows = snippetsStorage[trigger.text] {
                snippetsStorage[trigger.text] = existingWorkflows + [workflow]
              } else {
                snippetsStorage[trigger.text] = [workflow]
              }
              snippets.insert(trigger.text)
            default: break
            }
        } else {
            runCommands(in: workflow)
        }
    }
  }

  private func runCommands(in workflow: Workflow) {
    let commands = workflow.commands.filter(\.isEnabled)
    guard let machPortEvent = MachPortEvent.empty() else { return }
    switch workflow.execution {
    case .concurrent:
      commandRunner.concurrentRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    case .serial:
      commandRunner.serialRun(
        commands,
        checkCancellation: true,
        resolveUserEnvironment: workflow.resolveUserEnvironment(),
        shortcut: .empty(),
        machPortEvent: machPortEvent,
        repeatingEvent: false
      )
    }
  }
}
