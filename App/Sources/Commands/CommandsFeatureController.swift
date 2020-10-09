import Foundation
import LogicFramework
import ViewKit
import Combine
import Cocoa

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
  @Published var state: [CommandViewModel]
  let userSelection: UserSelection
  let groupsController: GroupsControlling
  let installedApplications: [Application]
  private var cancellables = [AnyCancellable]()

  init(groupsController: GroupsControlling,
       installedApplications: [Application],
       state: [CommandViewModel], userSelection: UserSelection) {
    self.groupsController = groupsController
    self.installedApplications = installedApplications
    self._state = Published(initialValue: state)
    self.userSelection = userSelection

    userSelection.$workflow.sink { workflow in
      self.state = workflow?.commands ?? []
    }.store(in: &cancellables)
  }

  func perform(_ action: CommandListView.Action) {
    guard let workflow = userSelection.workflow else { return }

    switch action {
    case .createCommand(let viewModel):
      createCommand(viewModel, in: workflow)
    case .updateCommand(let viewModel):
      updateCommand(viewModel, in: workflow)
    case .deleteCommand(let viewModel):
      deleteCommand(viewModel, in: workflow)
    case .moveCommand(let from, let to):
      moveCommand(from: from, to: to, in: workflow)
    case .runCommand:
      Swift.print("run command!")
    case .revealCommand:
      Swift.print("reveal command")
    }
  }

  // MARK: Private methods

  func createCommand(_ viewModel: CommandViewModel, in workflow: WorkflowViewModel) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    var workflow = context.model

    let command: Command = createCommand(from: viewModel)
    workflow.commands.append(command)
    delegate?.commandsFeatureController(self, didCreateCommand: command, in: workflow)
  }

  func updateCommand(_ viewModel: CommandViewModel, in workflow: WorkflowViewModel) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let previousCommand = context.model.commands.first(where: { $0.id == viewModel.id }),
          let index = context.model.commands.firstIndex(of: previousCommand) else { return }

    var workflow = context.model
    let command: Command = createCommand(from: viewModel)

    workflow.commands[index] = command
    delegate?.commandsFeatureController(self, didCreateCommand: command, in: workflow)
  }

  func moveCommand(from: Int, to: Int, in workflow: WorkflowViewModel) {
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

  func deleteCommand(_ viewModel: CommandViewModel, in workflow: WorkflowViewModel) {
    guard let context = groupsController.workflowContext(workflowId: workflow.id) else { return }
    guard let command = context.model.commands.first(where: { $0.id == viewModel.id }) else { return }

    let workflow = context.model

    delegate?.commandsFeatureController(self, didDeleteCommand: command, in: workflow)
  }

  private func createCommand(from viewModel: CommandViewModel) -> Command {
    let command: Command
    switch viewModel.kind {
    case .appleScript(let viewModel):
      command = .script(.appleScript(.path(viewModel.path), viewModel.id))
    case .application(let viewModel):
      let application = Application(bundleIdentifier: viewModel.bundleIdentifier,
                                    bundleName: viewModel.name,
                                    path: viewModel.path)
      command = .application(ApplicationCommand(
                              id: viewModel.id,
                              application: application))
    case .keyboard(let viewModel):
      let modifiers = viewModel.modifiers.swapNamespace
      let keyboardShortcut = KeyboardShortcut(
        id: viewModel.id,
        key: viewModel.key,
        modifiers: modifiers)
      command = .keyboard(KeyboardCommand(
                            id: viewModel.id,
                            keyboardShortcut: keyboardShortcut))
    case .openFile(let viewModel):
      let application: Application?
      if let selectedApplication = viewModel.application {
        application = self.application(from: selectedApplication)
      } else {
        application = defaultApplicationForPath(URL(fileURLWithPath: viewModel.path))
      }

      command = .open(OpenCommand(
                        id: viewModel.id,
                        application: application,
                        path: viewModel.path))
    case .openUrl(let viewModel):
      let application: Application?
      if let selectedApplication = viewModel.application {
        application = self.application(from: selectedApplication)
      } else {
        application = defaultApplicationForPath(viewModel.url)
      }
      command = .open(OpenCommand(application: application, path: viewModel.url.absoluteString))
    case .shellScript(let viewModel):
      command = .script(.shell(.path(viewModel.path), viewModel.id))
    }

    return command
  }

  private func application(from viewModel: ApplicationViewModel) -> Application? {
    return installedApplications.first(where: { $0.bundleIdentifier == viewModel.bundleIdentifier })
  }

  private func defaultApplicationForPath(_ url: URL) -> Application? {
    guard let applicationPath = NSWorkspace.shared.urlForApplication(toOpen: url) else { return nil }
    return installedApplications.first(where: { $0.path == applicationPath.path })
  }
}
