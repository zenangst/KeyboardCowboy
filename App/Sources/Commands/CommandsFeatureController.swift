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

final class CommandsFeatureController: ViewController {
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
    case .moveCommand(let command, let to):
      moveCommand(command, to: to, in: workflow)
    case .runCommand:
      Swift.print("run command!")
    case .revealCommand:
      Swift.print("reveal command")
    }
  }

  // MARK: Private methods

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

  private func moveCommand(_ command: Command, to index: Int, in workflow: Workflow) {
    var workflow = workflow
    var newIndex = index
    if let previousIndex = workflow.commands.firstIndex(of: command) {
      if newIndex > previousIndex {
        newIndex -= 1
      }
    }

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
