import Foundation
import LogicFramework
import ViewKit
import Combine
import ModelKit

protocol WorkflowFeatureControllerDelegate: AnyObject {
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 in group: Group)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow,
                                 in group: Group)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow,
                                 in group: Group)
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 in group: Group)
}

final class WorkflowFeatureController: ViewController,
                                 CommandsFeatureControllerDelegate,
                                 KeyboardShortcutsFeatureControllerDelegate {
  weak var delegate: WorkflowFeatureControllerDelegate?
  @Published var state: Workflow?
  var applications = [Application]()
  let groupsController: GroupsControlling
  private var cancellables = [AnyCancellable]()
  private let queue = DispatchQueue(label: "\(bundleIdentifier).WorkflowFeatureController", qos: .userInteractive)

  public init(state: Workflow,
              applications: [Application],
              groupsController: GroupsControlling) {
    self._state = Published(initialValue: state)
    self.applications = applications
    self.groupsController = groupsController
  }

  // MARK: ViewController

  func perform(_ action: WorkflowList.Action) {
    queue.async { [weak self] in
      guard let self = self else { return }
      switch action {
      case .createWorkflow(let group):
        self.createWorkflow(in: group)
      case .updateWorkflow(let workflow, let group):
        self.updateWorkflow(workflow, in: group)
      case .deleteWorkflow(let workflow, let group):
        self.deleteWorkflow(workflow, in: group)
      case .moveWorkflow(let workflow, let to, let group):
        self.moveWorkflow(workflow, to: to, in: group)
      case .drop(let urls, let workflow, let group):
        self.drop(urls, workflow: workflow, in: group)
      }
    }
  }

  // MARK: Private methods

  private func createWorkflow(in group: ModelKit.Group) {
    var group = group
    let workflow = Workflow.empty()
    group.workflows.add(workflow)
    delegate?.workflowFeatureController(self, didCreateWorkflow: workflow, in: group)
  }

  private func updateWorkflow(_ workflow: Workflow, in group: ModelKit.Group) {
    var group = group
    try? group.workflows.replace(workflow)
    delegate?.workflowFeatureController(self, didUpdateWorkflow: workflow, in: group)
  }

  private func deleteWorkflow(_ workflow: Workflow, in group: ModelKit.Group) {
    var group = group
    try? group.workflows.remove(workflow)
    delegate?.workflowFeatureController(self, didDeleteWorkflow: workflow, in: group)
  }

  private func moveWorkflow(_ workflow: Workflow, to index: Int, in group: ModelKit.Group) {
    var group = group
    try? group.workflows.move(workflow, to: index)
    delegate?.workflowFeatureController(self, didMoveWorkflow: workflow, in: group)
  }

  private func drop(_ urls: [URL], workflow: Workflow?, in group: Group) {
    var group = group
    let commands = generateCommands(urls)

    if var existingWorkflow = workflow {
      existingWorkflow.commands.append(contentsOf: commands)
      try? group.workflows.replace(existingWorkflow)
      delegate?.workflowFeatureController(self, didUpdateWorkflow: existingWorkflow, in: group)
    } else {
      var newWorkflow: Workflow = Workflow.empty()
      newWorkflow.commands = commands
      group.workflows.append(newWorkflow)
      delegate?.workflowFeatureController(self, didCreateWorkflow: newWorkflow, in: group)
    }
  }

  private func generateCommands(_ urls: [URL]) -> [Command] {
    var commands = [Command]()
    for url in urls {
      switch url.dropType {
      case .application:
        guard let application = applications.first(where: { $0.path == url.path })
        else { continue }
        let applicationCommand = ApplicationCommand(
          name: "Open \(application.bundleName)",
          application: application)
        commands.append(Command.application(applicationCommand))
      case .file:
        let name = "Open \(url.lastPathComponent)"
        commands.append(Command.open(.init(name: name, path: url.path)))
      case .web:
        var name = "Open URL"
        if let host = url.host {
          name = "Open \(host)/\(url.lastPathComponent)"
        }
        commands.append(Command.open(.init(name: name, path: url.absoluteString)))
      case .unsupported:
        continue
      }
    }
    return commands
  }

  // MARK: KeyboardShortcutsFeatureControllerDelegate

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didCreateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didUpdateKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didDeleteKeyboardShortcut keyboardShortcut: KeyboardShortcut,
                                         in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  // MARK: CommandsFeatureControllerDelegate

  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didCreateCommand command: Command,
                                 in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didUpdateCommand command: Command,
                                 in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDeleteCommand command: Command,
                                 in workflow: Workflow) {
    guard let group = groupsController.group(for: workflow) else { return }
    updateWorkflow(workflow, in: group)
  }
}

private enum DropType {
  case application
  case file
  case web
  case unsupported
}

private extension URL {
  var dropType: DropType {
    if isFileURL {
      if lastPathComponent.contains(".app") {
        return .application
      } else {
        return .file
      }
    } else {
      return .web
    }
  }
}
