import Apps
import Foundation

enum DetailViewActionReducerResult {
  case animated
  case rerender
  case none
}

final class DetailViewActionReducer {
  static func reduce(_ action: DetailView.Action,
                     commandEngine: CommandEngine,
                     keyboardCowboyEngine: KeyboardCowboyEngine,
                     applicationStore: ApplicationStore,
                     workflow: inout Workflow) -> DetailViewActionReducerResult {
    var result: DetailViewActionReducerResult = .rerender
    switch action {
    case .singleDetailView(let action):
      switch action {
      case .dropUrls(_, let urls):
        let commands = DropCommandsController.generateCommands(from: urls, applications: applicationStore.applications)
        workflow.commands.append(contentsOf: commands)
      case .updateKeyboardShortcuts(_, let keyboardShortcuts):
        workflow.trigger = .keyboardShortcuts(keyboardShortcuts)
      case .commandView(_, let action):
        DetailCommandActionReducer.reduce(
          action,
          keyboardCowboyEngine: keyboardCowboyEngine,
          workflow: &workflow)
      case .moveCommand(_, let fromOffsets, let toOffset):
        workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
        result = .animated
      case .updateName(_, let name):
        workflow.name = name
        result = .none
      case .setIsEnabled(_, let isEnabled):
        workflow.isEnabled = isEnabled
        result = .none
      case .removeCommands(_, let commandIds):
        workflow.commands.removeAll(where: { commandIds.contains($0.id) })
      case .trigger(_, let action):
        switch action {
        case .addKeyboardShortcut:
          workflow.trigger = .keyboardShortcuts([])
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
        let commands = workflow.commands.filter(\.isEnabled)
        switch workflow.execution {
        case .concurrent:
          commandEngine.concurrentRun(commands)
        case .serial:
          commandEngine.serialRun(commands)
        }
        return .none
      }
    }
    return result
  }
}
