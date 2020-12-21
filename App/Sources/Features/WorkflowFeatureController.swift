import Foundation
import LogicFramework
import ViewKit
import Combine
import ModelKit
import SwiftUI

protocol WorkflowFeatureControllerDelegate: AnyObject {
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didCreateWorkflow workflow: Workflow,
                                 groupId: String) throws
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didUpdateWorkflow workflow: Workflow) throws
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDeleteWorkflow workflow: Workflow) throws
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didMoveWorkflow workflow: Workflow,
                                 to offset: Int) throws
  func workflowFeatureController(_ controller: WorkflowFeatureController,
                                 didDropWorkflow workflow: Workflow,
                                 groupId: String) throws
}

final class WorkflowFeatureController: ViewController,
                                       CommandsFeatureControllerDelegate,
                                       KeyboardShortcutsFeatureControllerDelegate {
  @Published var state: Workflow = .empty()
  weak var delegate: WorkflowFeatureControllerDelegate?
  var applications = [Application]()
  private var cancellables = [AnyCancellable]()

  public init(applications: [Application]) {
    self.applications = applications
  }

  // MARK: ViewController

  func perform(_ action: WorkflowList.Action) {
    switch action {
    case .set(let workflow):
      self.state = workflow
    case .create(let groupId):
      create(groupId)
    case .duplicate(let workflow, let groupId):
      guard let groupId = groupId else { return }
      duplicate(workflow, groupId: groupId)
    case .update(let workflow):
      update(workflow)
    case .delete(let workflow):
      delete(workflow)
    case .move(let workflow, let to):
      move(workflow, to: to)
    case .drop(let urls, let groupId, let workflow):
      drop(urls, groupId: groupId, workflow: workflow)
    }
  }

  // MARK: Private methods

  private func create(_ groupId: String?) {
    guard let groupId = groupId else { return }
    let workflow = Workflow.empty()
    try? delegate?.workflowFeatureController(self, didCreateWorkflow: workflow, groupId: groupId)
  }

  private func duplicate(_ workflow: Workflow, groupId: String?) {
    guard let groupId = groupId else { return }

    let newWorkflow = Workflow(name: workflow.name,
                               keyboardShortcuts: workflow.keyboardShortcuts,
                               commands: workflow.commands)
    try? delegate?.workflowFeatureController(self, didCreateWorkflow: newWorkflow, groupId: groupId)
  }

  private func update(_ workflow: Workflow) {
    perform(.set(workflow: workflow))
    try? delegate?.workflowFeatureController(self, didUpdateWorkflow: workflow)
  }

  private func delete(_ workflow: Workflow) {
    try? delegate?.workflowFeatureController(self, didDeleteWorkflow: workflow)
  }

  private func move(_ workflow: Workflow, to index: Int) {
    try? delegate?.workflowFeatureController(self, didMoveWorkflow: workflow, to: index)
  }

  private func drop(_ urls: [URL], groupId: String?, workflow: Workflow?) {
    guard let groupId = groupId else { return }
    var targetWorkflow: Workflow
    let commands = generateCommands(urls)

    if var existingWorkflow = workflow {
      existingWorkflow.commands.append(contentsOf: commands)
      targetWorkflow = existingWorkflow
    } else {
      var newWorkflow: Workflow = Workflow.empty()
      newWorkflow.commands.append(contentsOf: commands)
      targetWorkflow = newWorkflow
    }

    try? delegate?.workflowFeatureController(self, didDropWorkflow: targetWorkflow, groupId: groupId)
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
                                         didCreateKeyboardShortcut keyboardShortcut: ModelKit.KeyboardShortcut,
                                         in workflow: Workflow) {
    update(workflow)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didUpdateKeyboardShortcut keyboardShortcut: ModelKit.KeyboardShortcut,
                                         in workflow: Workflow) {
    update(workflow)
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didDeleteKeyboardShortcut keyboardShortcut: ModelKit.KeyboardShortcut,
                                         in workflow: Workflow) {
    update(workflow)
  }

  // MARK: CommandsFeatureControllerDelegate

  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didCreateCommand command: Command,
                                 in workflow: Workflow) {
    update(workflow)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didUpdateCommand command: Command,
                                 in workflow: Workflow) {
    update(workflow)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDeleteCommand command: Command,
                                 in workflow: Workflow) {
    update(workflow)
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDropCommands commands: [Command],
                                 in workflow: Workflow) {
    update(workflow)
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
