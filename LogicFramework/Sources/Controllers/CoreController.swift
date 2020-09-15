import Foundation

public protocol CoreControlling {
  func reload()
  @discardableResult
  func activate(_ keyboardShortcuts: [KeyboardShortcut]) -> [Workflow]
}

public class CoreController: CoreControlling {
  let commandController: CommandControlling
  let groupsController: GroupsControlling
  let workflowController: WorkflowControlling
  let workspace: WorkspaceProviding

  private(set) var currentGroups = [Group]()
  private(set) var currentKeyboardShortcuts = [KeyboardShortcut]()

  public init(commandController: CommandControlling,
              groupsController: GroupsControlling,
              workflowController: WorkflowControlling,
              workspace: WorkspaceProviding) {
    self.commandController = commandController
    self.groupsController = groupsController
    self.workspace = workspace
    self.workflowController = workflowController
    self.reload()
  }

  public func reload() {
    var contextRule = Rule()

    if let runningApplication = workspace.frontApplication,
       let bundleIdentifier = runningApplication.bundleIdentifier {
      contextRule.applications = [
        Application(bundleIdentifier: bundleIdentifier, bundleName: "", path: "")
      ]
    }

    if let weekDay = DateComponents().weekday,
       let day = Rule.Day(rawValue: weekDay) {
      contextRule.days = [day]
    }

    currentGroups = groupsController.filterGroups(using: contextRule)
    currentKeyboardShortcuts = []
  }

  public func activate(_ keyboardShortcuts: [KeyboardShortcut]) -> [Workflow] {
    currentKeyboardShortcuts.append(contentsOf: keyboardShortcuts)
    let workflows = workflowController.filterWorkflows(
      from: currentGroups,
      keyboardShortcuts: currentKeyboardShortcuts)

    if workflows.count == 1 {
      reload()
      for workflow in workflows {
        commandController.run(workflow.commands)
      }
    }

    return workflows
  }
}
