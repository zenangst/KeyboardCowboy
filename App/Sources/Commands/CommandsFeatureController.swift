import Foundation
import LogicFramework
import ViewKit
import Combine
import Cocoa
import ModelKit

protocol CommandsFeatureControllerDelegate: AnyObject {
  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didCreateCommand command: Command, in workflow: Workflow)
  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didUpdateCommand command: Command, in workflow: Workflow)
  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didDeleteCommand command: Command, in workflow: Workflow)
}

final class CommandsFeatureController: ActionController {
  weak var delegate: CommandsFeatureControllerDelegate?
  let groupsController: GroupsControlling
  let installedApplications: [Application]
  private let workspace: WorkspaceProviding
  private let commandController: CommandControlling

  init(commandController: CommandControlling,
       groupsController: GroupsControlling,
       installedApplications: [Application],
       workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.commandController = commandController
    self.groupsController = groupsController
    self.installedApplications = installedApplications
    self.workspace = workspace
  }

  func perform(_ action: CommandListView.Action) {
    switch action {
    case .createCommand(let command, let workflow):
      createCommand(command, in: workflow)
    case .updateCommand(let command, let workflow):
      updateCommand(command, in: workflow)
    case .deleteCommand(let command, let workflow):
      deleteCommand(command, in: workflow)
    case .moveCommand(let command, let offset, let workflow):
      moveCommand(command, to: offset, in: workflow)
    case .runCommand(let command):
      run(command)
    case .revealCommand(let command, _):
      reveal(command)
    }
  }

  // MARK: Private methods

  private func reveal(_ command: Command) {
    switch command {
    case .application(let applicationCommand):
      self.workspace.reveal(applicationCommand.application.path)
    case .open(let openCommand):

      if openCommand.isUrl {
        self.commandController.run([command])
      } else {
        self.workspace.reveal(openCommand.path)
      }
    case .script(let command):
      switch command {
      case .appleScript(.path(let path), _):
        self.workspace.reveal(path)
      case .shell(.path(let path), _):
        self.workspace.reveal(path)
      case .appleScript(.inline, _), .shell(.inline, _):
        break
      }
    case .keyboard:
      break
    }
  }

  private func run(_ command: Command) {
    commandController.run([command])
  }

  private func createCommand(_ command: Command, in workflow: Workflow) {
    var workflow = workflow
    workflow.commands.append(command)
    delegate?.commandsFeatureController(self, didCreateCommand: command, in: workflow)
  }

  private func updateCommand(_ command: Command, in workflow: Workflow) {
    var workflow = workflow
    try? workflow.commands.replace(command)
    delegate?.commandsFeatureController(self, didCreateCommand: command, in: workflow)
  }

  private func moveCommand(_ command: Command, to offset: Int, in workflow: Workflow) {
    guard let currentIndex = workflow.commands.firstIndex(of: command) else { return }

    let newIndex = currentIndex + offset
    var workflow = workflow
    try? workflow.commands.move(command, to: newIndex)
    delegate?.commandsFeatureController(self, didUpdateCommand: command, in: workflow)
  }

  private func deleteCommand(_ command: Command, in workflow: Workflow) {
    var workflow = workflow
    try? workflow.commands.remove(command)
    delegate?.commandsFeatureController(self, didDeleteCommand: command, in: workflow)
  }

  private func application(from command: Application) -> Application? {
    return installedApplications.first(where: { $0.bundleIdentifier == command.bundleIdentifier })
  }

  private func defaultApplicationForPath(_ url: URL) -> Application? {
    guard let applicationPath = NSWorkspace.shared.urlForApplication(toOpen: url) else { return nil }
    return installedApplications.first(where: { $0.path == applicationPath.path })
  }
}
