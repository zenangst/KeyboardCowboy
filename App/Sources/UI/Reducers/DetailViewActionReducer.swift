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
      case .commandView(_, let action):
        DetailCommandActionReducer.reduce(action, commandRunner: commandRunner, workflow: &workflow)
      case .moveCommand(_, let fromOffsets, let toOffset):
        workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
        result = .animated(.default)
      case .setIsEnabled(_, let isEnabled):
        workflow.isEnabled = isEnabled
        result = .none
      case .removeCommands(_, let commandIds):
        workflow.commands.removeAll(where: { commandIds.contains($0.id) })
        result = .animated(.default)
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
          commandRunner.concurrentRun(commands, checkCancellation: true, resolveUserEnvironment: true,
                                      machPortEvent: machPortEvent, repeatingEvent: false)
        case .serial:
          commandRunner.serialRun(commands, checkCancellation: true, resolveUserEnvironment: true,
                                  machPortEvent: machPortEvent, repeatingEvent: false)
        }
        return .none
      }
    }
    return result
  }
}
