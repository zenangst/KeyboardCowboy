import Foundation
import Cocoa
import MachPort

final class DetailCommandActionReducer {
  static func reduce(_ action: CommandView.Action,
                     commandRunner: CommandRunner,
                     workflow: inout  Workflow) {
    guard var command: Command = workflow.commands.first(where: { $0.id == action.commandId }) else { return }

    switch action {
    case .updateName(_, let newValue):
      command.name = newValue
      workflow.updateOrAddCommand(command)
    case .changeDelay(_, let newValue):
      command.delay = newValue
      workflow.updateOrAddCommand(command)
    case .toggleEnabled(_, let newValue):
      command.isEnabled = newValue
      workflow.updateOrAddCommand(command)
    case .toggleNotify(_, let newValue):
      command.notification = newValue
      workflow.updateOrAddCommand(command)
    case .run(_):
      let runCommand = command
      Task {
        do {
          guard let machPortEvent = MachPortEvent.empty() else { return }
          var runtimeDictionary = [String: String]()
          try await commandRunner.run(runCommand,
                                      workflowCommands: [runCommand],
                                      snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: false),
                                      shortcut: .empty(),
                                      machPortEvent: machPortEvent,
                                      checkCancellation: false,
                                      repeatingEvent: false,
                                      runtimeDictionary: &runtimeDictionary)
        } catch let error as KeyboardCommandRunnerError {
          let alert = await NSAlert(error: error)
          await alert.runModal()
        } catch let error as AppleScriptPluginError {
          let alert: NSAlert
          switch error {
          case .failedToCreateInlineScript:
            alert = await NSAlert(error: error)
          case .failedToCreateScriptAtURL:
            alert = await NSAlert(error: error)
          case .compileFailed(let error):
            alert = await NSAlert(error: error)
          case .executionFailed(let error):
            alert = await NSAlert(error: error)
          }

          await alert.runModal()
        }
      }
    case .remove(let payload):
      workflow.commands.removeAll(where: { $0.id == payload.commandId })
    case .modify(let kind):
      switch kind {
      case .application(let action, _):
        guard case .application(var applicationCommand) = command else {
          fatalError("Wrong command type")
        }
        switch action {
        case .changeApplication(let application):
          applicationCommand.application = application
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .changeApplicationAction(let action):
          applicationCommand.action = switch action { 
          case .open:   .open
          case .close:  .close
          case .hide:   .hide
          case .unhide: .unhide
          }
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
        case .changeApplicationModifier(let modifier, let newValue):
          if newValue {
            applicationCommand.modifiers.insert(modifier)
          } else {
            applicationCommand.modifiers.remove(modifier)
          }
          command = .application(applicationCommand)
          workflow.updateOrAddCommand(command)
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .builtIn(let action, _):
        switch action {
        case .update(let newCommand):
          command = .builtIn(newCommand)
          workflow.updateOrAddCommand(command)
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .bundled(let action, _):
        switch action {
        case .editCommand(let kind):
          switch kind {
          case .workspace(let workspace):
            let newWorkspaceCommand = WorkspaceCommand(
              id: command.id,
              bundleIdentifiers: workspace.applications.map(\.bundleIdentifier),
              hideOtherApps: workspace.hideOtherApps,
              tiling: workspace.tiling
            )
            command = .bundled(.init(.workspace(newWorkspaceCommand), meta: command.meta))
            workflow.updateOrAddCommand(command)
          }
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .keyboard(let action, _):
        switch action {
        case .updateKeyboardShortcuts(let keyboardShortcuts):
          command = .keyboard(.init(id: command.id, name: command.name, keyboardShortcuts: keyboardShortcuts, notification: command.notification))
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .updateIterations(let newIterations):
          switch command {
          case .keyboard(let keyboardCommand):
            command = .keyboard(
              .init(id: keyboardCommand.id,
                    name: keyboardCommand.name,
                    keyboardShortcuts: keyboardCommand.keyboardShortcuts,
                    iterations: newIterations,
                    notification: keyboardCommand.notification
                   ))
            workflow.updateOrAddCommand(command)
          default:
            break
          }
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        case .editCommand:
          break // NOOP
        }
      case .mouse(let action, _):
        switch action {
        case .update(let kind):
          if case var .mouse(mouseCommand) = command {
            mouseCommand.kind = kind
            workflow.updateOrAddCommand(.mouse(mouseCommand))
          }
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .open(let action, _):
        switch action {
        case .updatePath(let newPath):
          if case var .open(openCommand) = command {
            openCommand.name = newPath
            openCommand.path = newPath
            command = .open(openCommand)
          } else {
            fatalError("This shouldn't happen.")
          }
          workflow.updateOrAddCommand(command)
        case .openWith(let application):
          if case .open(let oldCommand) = command {
            let newCommand = OpenCommand(
              id: oldCommand.id,
              name: oldCommand.name,
              application: application,
              path: oldCommand.path,
              notification: command.notification
            )
            command = .open(newCommand)
            workflow.updateOrAddCommand(command)
          }
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        case .reveal(let path):
          NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
      case .script(let action, _):
        switch action {
        case .updateSource(let model):
          let kind: ScriptCommand.Kind
          kind = switch model.scriptExtension {
          case .appleScript: .appleScript
          case .shellScript: .shellScript
          }

          let variableName: String?
          if !model.variableName.isEmpty {
            variableName = model.variableName
          } else {
            variableName = nil
          }

          command = .script(.init(id: command.id,
                                  name: command.name, kind: kind, source: model.source,
                                  notification: command.meta.notification,
                                  variableName: variableName))
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .open(let source):
          Task {
            guard let machPortEvent = MachPortEvent.empty() else { return }
            let path = (source as NSString).expandingTildeInPath
            var runtimeDictionary = [String: String]()
            try await commandRunner.run(
              .open(.init(path: path)),
              workflowCommands: [],
              snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: false),
              shortcut: .empty(),
              machPortEvent: machPortEvent,
              checkCancellation: false,
              repeatingEvent: false,
              runtimeDictionary: &runtimeDictionary
            )
          }
        case .reveal(let path):
          NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        case .edit:
          break
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .shortcut(let action, _):
        switch action {
        case .createShortcut:
          try? SBShortcuts.createShortcut()
        case .updateShortcut(let shortcutName):
          command = .shortcut(
            .init(
              id: command.id,
              shortcutIdentifier: shortcutName,
              name: command.name,
              isEnabled: command.isEnabled,
              notification: command.notification
            )
          )
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .openShortcut:
          try? SBShortcuts.openShortcut(command.name)
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .type(let action, _):
        switch action {
        case .updateMode(let newMode):
          switch command {
          case .text(let typeCommand):
            switch typeCommand.kind {
            case .insertText(let newCommand):
              command = .text(.init(.insertText(.init(newCommand.input, mode: newMode, meta: newCommand.meta))))
            }
          default:
            fatalError("Wrong command type")
          }
          workflow.updateOrAddCommand(command)
        case .updateName(let newName):
          command.name = newName
          workflow.updateOrAddCommand(command)
        case .updateSource(let newInput):
          switch command {
          case .text(let typeCommand):
            switch typeCommand.kind {
            case .insertText(var typeCommand):
              typeCommand.input = newInput
              command = .text(.init(.insertText(typeCommand)))
            }
          default:
            fatalError("Wrong command type")
          }
          workflow.updateOrAddCommand(command)
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        }
      case .system(let action, _):
        switch action {
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        case .updateKind(let newKind):
          if case .systemCommand(let oldCommand) = command {
            command = .systemCommand(.init(id: oldCommand.id, name: oldCommand.name,
                                           kind: newKind,
                                           notification: command.notification))
            workflow.updateOrAddCommand(command)
          }
        }
      case .uiElement(let action, _):
        switch action {
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        case .updateCommand(let newCommand):
          command = .uiElement(newCommand)
          workflow.updateOrAddCommand(command)
        }
      case .window(let action, _):
        switch action {
        case .commandAction(let action):
          DetailCommandContainerActionReducer.reduce(action, command: &command, workflow: &workflow)
          workflow.updateOrAddCommand(command)
        case .onUpdate(let newModel):
          if case .windowManagement(let oldCommand) = command {
            command = .windowManagement(.init(id: oldCommand.id,
                                              name: oldCommand.name, 
                                              kind: newModel.kind,
                                              notification: oldCommand.notification,
                                              animationDuration: newModel.animationDuration))
            workflow.updateOrAddCommand(command)
          }
        }
      }
    }
  }
}
