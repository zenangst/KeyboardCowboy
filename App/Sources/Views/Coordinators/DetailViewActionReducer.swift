import Apps
import Foundation

final class DetailViewActionReducer {
  static func reduce(_ action: DetailView.Action,
                     keyboardCowboyEngine: KeyboardCowboyEngine,
                     workflow: inout Workflow) async {
    switch action {
    case .singleDetailView(let action):
      switch action {
      case .updateKeyboardShortcuts(_, let keyboardShortcuts):
        workflow.trigger = .keyboardShortcuts(keyboardShortcuts)
      case .commandView(_, let action):
        await DetailCommandActionReducer.reduce(
          action,
          keyboardCowboyEngine: keyboardCowboyEngine,
          workflow: &workflow)
      case .moveCommand(_, let fromOffsets, let toOffset):
        workflow.commands.move(fromOffsets: fromOffsets, toOffset: toOffset)
      case .updateName(_, let name):
        workflow.name = name
      case .setIsEnabled(_, let isEnabled):
        workflow.isEnabled = isEnabled
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
      }
    }
  }
}
