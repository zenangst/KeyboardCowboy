import Foundation
import LogicFramework
import ViewKit
import Combine
import ModelKit
import SwiftUI

protocol WorkflowsFeatureControllerDelegate: AnyObject {
  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didCreateWorkflow workflow: Workflow,
                                  groupId: String) throws
  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didUpdateWorkflow workflow: Workflow) throws
  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didDeleteWorkflow workflow: Workflow) throws
  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didMoveWorkflow workflow: Workflow,
                                  to offset: Int) throws
  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didDropWorkflow workflow: Workflow,
                                  groupId: String) throws
  func workflowsFeatureController(_ controller: WorkflowsFeatureController,
                                  didTransferWorkflowIds workflowIds: Set<String>,
                                  toGroup group: ModelKit.Group) throws
}

final class WorkflowsFeatureController: ViewController,
                                        WorkflowFeatureControllerDelegate,
                                        CommandsFeatureControllerDelegate,
                                        KeyboardShortcutsFeatureControllerDelegate {
  @Published var state: [ModelKit.Workflow] = []
  weak var delegate: WorkflowsFeatureControllerDelegate?
  var applications = [Application]()
  let workflowController: WorkflowController
  private var cancellables = [AnyCancellable]()

  public init(applications: [Application],
              workflowController: WorkflowController) {
    self.applications = applications
    self.workflowController = workflowController
  }

  // MARK: ViewController

  func perform(_ action: WorkflowList.Action) {
    switch action {
    case .set(let group):
      self.state = group.workflows
    case .create(let groupId):
      create(groupId)
    case .duplicate(let workflow, let groupId):
      guard let groupId = groupId else { return }
      duplicate(workflow, groupId: groupId)
    case .update(let workflow):
      update(workflow)
    case .delete(let workflow):
      delete(workflow)
    case .deleteMultiple(let ids):
      deleteMultiple(ids)
    case .move(let workflow, let to):
      move(workflow, to: to)
    case .drop(let urls, let groupId, let workflow):
      drop(urls, groupId: groupId, workflow: workflow)
    case .transfer(let workflowIds, let group):
      transferWorkflows(workflowIds, to: group)
    }
  }

  // MARK: Private methods

  private func create(_ groupId: String?) {
    guard let groupId = groupId else { return }
    let workflow = Workflow.empty()
    try? delegate?.workflowsFeatureController(self, didCreateWorkflow: workflow, groupId: groupId)
  }

  private func duplicate(_ workflow: Workflow, groupId: String?) {
    guard let groupId = groupId else { return }

    let newWorkflow = Workflow(name: workflow.name,
                               keyboardShortcuts: workflow.keyboardShortcuts,
                               commands: workflow.commands)
    try? delegate?.workflowsFeatureController(self, didCreateWorkflow: newWorkflow, groupId: groupId)
  }

  private func update(_ workflow: Workflow) {
    try? delegate?.workflowsFeatureController(self, didUpdateWorkflow: workflow)
  }

  private func delete(_ workflow: Workflow) {
    try? delegate?.workflowsFeatureController(self, didDeleteWorkflow: workflow)
  }

  private func deleteMultiple(_ ids: Set<String>) {
    let workflows = state.filter({ ids.contains($0.id) })
    for workflow in workflows {
      delete(workflow)
    }
  }

  private func move(_ workflow: Workflow, to index: Int) {
    try? delegate?.workflowsFeatureController(self, didMoveWorkflow: workflow, to: index)
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

      if commands.count == 1, let firstCommand = commands.first {
        newWorkflow.name = firstCommand.name
      }

      newWorkflow.commands.append(contentsOf: commands)
      targetWorkflow = newWorkflow
    }

    try? delegate?.workflowsFeatureController(self, didDropWorkflow: targetWorkflow, groupId: groupId)
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
      case .applescript:
        let name = "Run \(url.lastPathComponent)"
        commands.append(Command.script(.appleScript(.path(url.path), name)))
      case .shellscript:
        let name = "Run \(url.lastPathComponent)"
        commands.append(Command.script(.shell(.path(url.path), name)))
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

  private func transferWorkflows(_ ids: Set<String>, to group: ModelKit.Group) {
    try? delegate?.workflowsFeatureController(self, didTransferWorkflowIds: ids, toGroup: group)
  }

  // MARK: WorkflowFeatureControllerDelegate

  func workflowFeatureController(_ controller: WorkflowFeatureController, didUpdateWorkflow workflow: Workflow) {
    update(workflow)
  }

  // MARK: KeyboardShortcutsFeatureControllerDelegate

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didCreateKeyboardShortcut keyboardShortcut: ModelKit.KeyboardShortcut,
                                         in workflow: Workflow) {
    workflowController.perform(.set(workflow: workflow))
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didUpdateKeyboardShortcut keyboardShortcut: ModelKit.KeyboardShortcut,
                                         in workflow: Workflow) {
    workflowController.perform(.set(workflow: workflow))
  }

  func keyboardShortcutFeatureController(_ controller: KeyboardShortcutsFeatureController,
                                         didDeleteKeyboardShortcut keyboardShortcut: ModelKit.KeyboardShortcut,
                                         in workflow: Workflow) {
    workflowController.perform(.set(workflow: workflow))
  }

  // MARK: CommandsFeatureControllerDelegate

  func commandsFeatureController(_ controller: CommandsFeatureController,
                                 didCreateCommand command: Command,
                                 in workflow: Workflow) {
    workflowController.perform(.set(workflow: workflow))
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didUpdateCommand command: Command,
                                 in workflow: Workflow) {
    workflowController.perform(.set(workflow: workflow))
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDeleteCommand command: Command,
                                 in workflow: Workflow) {
    workflowController.perform(.set(workflow: workflow))
  }

  func commandsFeatureController(_ controller: CommandsFeatureController, didDropUrls urls: [URL],
                                 in workflow: Workflow) {
    var workflow = workflow
    let commands = generateCommands(urls)
    workflow.commands.append(contentsOf: commands)
    workflowController.perform(.set(workflow: workflow))
  }
}

private enum DropType {
  case application
  case applescript
  case shellscript
  case file
  case web
  case unsupported
}

private extension URL {
  var dropType: DropType {
    if isFileURL {
      if lastPathComponent.contains(".app") {
        return .application
      } else if lastPathComponent.contains(".sh") {
        return .shellscript
      } else if lastPathComponent.contains(".scpt") {
        return .applescript
      } else {
        return .file
      }
    } else {
      return .web
    }
  }
}
