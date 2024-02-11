import Apps
import Foundation
import MachPort
import SwiftUI

enum DetailViewActionReducerResult {
  case animated(_ animation: Animation)
  case refresh
  case none
}

final class DetailViewActionReducer {
  @MainActor
  static func reduce(_ action: DetailView.Action,
                     commandRunner: CommandRunner,
                     selectionManager: SelectionManager<CommandViewModel>,
                     keyboardCowboyEngine: KeyboardCowboyEngine,
                     applicationStore: ApplicationStore,
                     workflow: inout Workflow) -> DetailViewActionReducerResult {
    var result: DetailViewActionReducerResult = .refresh
    switch action {
    case .singleDetailView(let action):
      switch action {
      case .duplicate(_, let commandIds):
        var newIds = Set<CommandViewModel.ID>()
        for commandId in commandIds {
          guard let command = workflow.commands.first(where: { $0.id == commandId }) else {
            continue
          }

          let copy = command.copy()
          if let index = workflow.commands.firstIndex(where: { $0.id == commandId }) {
            workflow.commands.insert(copy, at: index)
          } else {
            workflow.commands.append(copy)
          }
          newIds.insert(copy.id)
        }

        selectionManager.publish(newIds)
        result = .animated(.easeInOut(duration: 0.15))
      case .togglePassthrough:
        if case .keyboardShortcuts(var previousTrigger) = workflow.trigger {
          previousTrigger.passthrough.toggle()
          workflow.trigger = .keyboardShortcuts(previousTrigger)
        }
      case .dropUrls(_, let urls):
        let commands = DropCommandsController.generateCommands(from: urls, applications: applicationStore.applications)
        workflow.commands.append(contentsOf: commands)
        result = .animated(.default)
      case .updateKeyboardShortcuts(_, let passthrough, let holdDuration, let keyboardShortcuts):
        workflow.trigger = .keyboardShortcuts(
          .init(
            passthrough: passthrough,
            holdDuration: holdDuration,
            shortcuts: keyboardShortcuts
          )
        )
      case .updateHoldDuration(_, let holdDuration):
        guard case .keyboardShortcuts(var trigger) = workflow.trigger else {
          return .none
        }
        trigger.holdDuration = holdDuration
        workflow.trigger = .keyboardShortcuts(trigger)
      case .commandView(_, let action):
        DetailCommandActionReducer.reduce(action, commandRunner: commandRunner, workflow: &workflow)
      case .moveCommand(_, let fromOffsets, let toOffset):
        workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
        result = .animated(.default)
      case .updateName(_, let name):
        workflow.name = name
        result = .none
      case .setIsEnabled(_, let isEnabled):
        workflow.isEnabled = isEnabled
        result = .none
      case .removeCommands(_, let commandIds):
        workflow.commands.removeAll(where: { commandIds.contains($0.id) })
        result = .animated(.default)
      case .trigger(_, let action):
        switch action {
        case .addKeyboardShortcut:
          workflow.trigger = .keyboardShortcuts(.init(shortcuts: []))
        case .removeKeyboardShortcut:
          workflow.trigger = nil
        case .addApplication:
          workflow.trigger = .application([])
        }
      case .removeTrigger(_):
        workflow.trigger = nil
      case .applicationTrigger(_, let action):
        switch action {
        case .updateApplicationTriggers(let triggers):
          let applicationTriggers = triggers
            .map { viewModelTrigger in
              var contexts = Set<ApplicationTrigger.Context>()
              if viewModelTrigger.contexts.contains(.closed) {
                contexts.insert(.closed)
              } else {
                contexts.remove(.closed)
              }

              if viewModelTrigger.contexts.contains(.frontMost) {
                contexts.insert(.frontMost)
              } else {
                contexts.remove(.frontMost)
              }

              if viewModelTrigger.contexts.contains(.launched) {
                contexts.insert(.launched)
              } else {
                contexts.remove(.launched)
              }

              return ApplicationTrigger(id: viewModelTrigger.id,
                                        application: viewModelTrigger.application,
                                        contexts: Array(contexts))
            }
          workflow.trigger = .application(applicationTriggers)
        case .updateApplicationTriggerContext(let viewModelTrigger):
          if case .application(var previousTriggers) = workflow.trigger,
             let index = previousTriggers.firstIndex(where: { $0.id == viewModelTrigger.id }) {
            var newTrigger = previousTriggers[index]

            if viewModelTrigger.contexts.contains(.closed) {
              newTrigger.contexts.insert(.closed)
            } else {
              newTrigger.contexts.remove(.closed)
            }

            if viewModelTrigger.contexts.contains(.frontMost) {
              newTrigger.contexts.insert(.frontMost)
            } else {
              newTrigger.contexts.remove(.frontMost)
            }

            if viewModelTrigger.contexts.contains(.launched) {
              newTrigger.contexts.insert(.launched)
            } else {
              newTrigger.contexts.remove(.launched)
            }

            previousTriggers[index] = newTrigger
            workflow.trigger = .application(previousTriggers)
          }
        }
      case .updateExecution(_, let execution):
          switch execution {
            case .concurrent:
              workflow.execution = .concurrent
            case .serial:
              workflow.execution = .serial
          }
      case .runWorkflow:
        guard let machPortEvent = MachPortEvent.empty() else { return .none }

        let commands = workflow.commands.filter(\.isEnabled)
        switch workflow.execution {
        case .concurrent:
          commandRunner.concurrentRun(
            commands, checkCancellation: true,
            resolveUserEnvironment: true, shortcut: .empty(),
            machPortEvent: machPortEvent,
            repeatingEvent: false
          )
        case .serial:
          commandRunner.serialRun(
            commands, checkCancellation: true,
            resolveUserEnvironment: true, shortcut: .empty(),
            machPortEvent: machPortEvent,
            repeatingEvent: false
          )
        }
        return .none
      }
    }
    return result
  }
}
