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

class CommandsFeatureController: ViewController {
  weak var delegate: CommandsFeatureControllerDelegate?
  @Published var state: [Command]
  let userSelection: UserSelection
  let groupsController: GroupsControlling
  let installedApplications: [Application]
  private var cancellables = [AnyCancellable]()

  init(groupsController: GroupsControlling,
       installedApplications: [Application],
       state: [Command], userSelection: UserSelection) {
    self.groupsController = groupsController
    self.installedApplications = installedApplications
    self._state = Published(initialValue: state)
    self.userSelection = userSelection

    userSelection.$workflow.sink { [weak self] workflow in
      guard let self = self else { return }
      self.state = workflow?.commands ?? []
    }.store(in: &cancellables)
  }

  func perform(_ action: CommandListView.Action) {
    guard let workflow = userSelection.workflow else { return }

    switch action {
    case .createCommand(let command):
      createCommand(command, in: workflow)
    case .updateCommand(let command):
      updateCommand(command, in: workflow)
    case .deleteCommand(let command):
      deleteCommand(command, in: workflow)
    case .moveCommand(let from, let to):
      moveCommand(from: from, to: to, in: workflow)
    case .runCommand:
      Swift.print("run command!")
    case .revealCommand:
      Swift.print("reveal command")
    }
  }

  // MARK: Private methods

  func createCommand(_ command: Command, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    var workflow = context.model

    workflow.commands.append(command)
    delegate?.commandsFeatureController(self, didCreateCommand: command, in: workflow)
  }

  func updateCommand(_ command: Command, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let index = context.model.commands.firstIndex(where: { $0.id == command.id }) else { return }

    var workflow = context.model

    workflow.commands[index] = command
    delegate?.commandsFeatureController(self, didCreateCommand: command, in: workflow)
  }

  func moveCommand(from: Int, to: Int, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    var workflow = context.model
    let command = workflow.commands.remove(at: from)

    if to > workflow.commands.count {
      workflow.commands.append(command)
    } else {
      workflow.commands.insert(command, at: to)
    }

    delegate?.commandsFeatureController(self, didUpdateCommand: command, in: workflow)
  }

  func deleteCommand(_ command: Command, in workflow: Workflow) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }

    let workflow = context.model

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
