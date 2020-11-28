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
  private let queue = DispatchQueue(label: "\(bundleIdentifier).CommandsFeatureController", qos: .userInteractive)

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
    queue.async { [weak self] in
      guard let self = self else { return }
      switch action {
      case .createCommand(let command, let workflow):
        self.createCommand(command, in: workflow)
      case .updateCommand(let command, let workflow):
        self.updateCommand(command, in: workflow)
      case .deleteCommand(let command, let workflow):
        self.deleteCommand(command, in: workflow)
      case .moveCommand(let command, let offset, let workflow):
        self.moveCommand(command, to: offset, in: workflow)
      case .runCommand(let command):
        self.run(command)
      case .revealCommand(let command, _):
        self.reveal(command)
      }
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
