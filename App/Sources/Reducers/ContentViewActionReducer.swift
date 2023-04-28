import Foundation

final class ContentViewActionReducer {
  @MainActor
  static func reduce(_ action: ContentView.Action,
                     groupStore: GroupStore,
                     selectionPublisher: SelectionManager<ContentViewModel>,
                     group: inout WorkflowGroup) {
    switch action {
    case .moveWorkflowsToGroup(let groupId, let workflows):
      groupStore.move(workflows, to: groupId)
      if let updatedGroup = groupStore.group(withId: group.id) {
        group = updatedGroup
      }
    case .rerender:
      break
    case .addCommands(let workflowId, let commandIds):
      guard let index = group.workflows.firstIndex(where: { $0.id == workflowId }) else {
        return
      }
      var workflow = group.workflows[index]
      var commands = group.workflows.flatMap(\.commands)
        .filter({ commandIds.contains($0.id) })

      for (offset, _) in commands.enumerated() {
        commands[offset].id = UUID().uuidString
      }

      // We need to create copies of the commands.

      workflow.commands.append(contentsOf: commands)
      group.workflows[index] = workflow
    case .addWorkflow(let workflowId):
      let workflow = Workflow.empty(id: workflowId)
      group.workflows.append(workflow)
    case .removeWorflows(let ids):
      group.workflows.removeAll(where: { ids.contains($0.id) })
    case .moveWorkflows(let source, let destination):
      group.workflows.move(fromOffsets: source, toOffset: destination)
    case .selectWorkflow:
      break
    }
  }
}

extension Workflow.Trigger {
  func asViewModel() -> DetailViewModel.Trigger {
    switch self {
    case .application(let triggers):
      return .applications(
        triggers.map { trigger in
          DetailViewModel.ApplicationTrigger(id: trigger.id,
                                             name: trigger.application.displayName,
                                             application: trigger.application,
                                             contexts: trigger.contexts.map {
            switch $0 {
            case .closed:
              return .closed
            case .frontMost:
              return .frontMost
            case .launched:
              return .launched
            }
          })
        }
      )
    case .keyboardShortcuts(let shortcuts):
      return .keyboardShortcuts(shortcuts)
    }
  }
}

extension DetailView.Action {
  var workflowId: String? {
    switch self {
    case .singleDetailView(let action):
      return action.workflowId
    }
  }
}

extension CommandView.Kind {
  var workflowId: DetailViewModel.ID {
    switch self {
    case .application(_, let workflowId, _),
        .keyboard(_, let workflowId, _),
        .open(_, let workflowId, _),
        .script(_, let workflowId, _),
        .shortcut(_, let workflowId, _),
        .type(_, let workflowId, _),
        .system(_, let workflowId, _):
      return workflowId
    }
  }

  var commandId: DetailViewModel.CommandViewModel.ID {
    switch self {
    case .application(_, _, let commandId),
        .keyboard(_, _, let commandId),
        .open(_, _, let commandId),
        .script(_, _, let commandId),
        .shortcut(_, _, let commandId),
        .type(_, _, let commandId),
        .system(_, _, let commandId):
      return commandId
    }
  }
}

extension CommandView.Action {
  var workflowId: DetailViewModel.ID {
    switch self {
    case .toggleEnabled(let workflowId, _, _):
      return workflowId
    case .modify(let kind):
      return kind.workflowId
    case .run(let workflowId, _),
        .remove(let workflowId, _):
      return workflowId
    }
  }

  var commandId: DetailViewModel.CommandViewModel.ID {
    switch self {
    case .toggleEnabled(_, let commandId, _):
      return commandId
    case .modify(let kind):
      return kind.commandId
    case .run(_, let commandId),
        .remove(_, let commandId):
      return commandId
    }
  }
}

extension SingleDetailView.Action {
  var workflowId: String {
    switch self {
    case .dropUrls(let workflowId, _):
      return workflowId
    case .updateKeyboardShortcuts(let workflowId, _):
      return workflowId
    case .removeTrigger(let workflowId):
      return workflowId
    case .setIsEnabled(let workflowId, _):
      return workflowId
    case .removeCommands(let workflowId, _):
      return workflowId
    case .applicationTrigger(let workflowId, _):
      return workflowId
    case .commandView(let workflowId, _):
      return workflowId
    case .moveCommand(let workflowId, _, _):
      return workflowId
    case .trigger(let workflowId, _):
      return workflowId
    case .updateName(let workflowId, _):
      return workflowId
    case .updateExecution(let workflowId, _):
      return workflowId
    case .runWorkflow(let workflowId):
      return workflowId
    }
  }
}
