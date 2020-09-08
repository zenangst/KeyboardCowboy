import Foundation

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  func groupList() -> [Group] {
    [
      Group(
        name: "Applications",
        workflows: openWorkflows("Calendar", "Contacts", "Finder", "Mail", "Safari", "Xcode")
      ),
      Group(
        name: "Developer tools",
        workflows: openWorkflows("Instruments", "Simulator", "Xcode")
      ),
      Group(
        name: "Folders",
        workflows: openWorkflows("Home folder", "Developer folder")
      ),
      Group(
        name: "Files",
        workflows: openWorkflows(".gitconfig", "Design project.sketch", "Keyboard-Cowboy.xcodeproj")
      ),
      Group(
        name: "Keyboard shortcuts",
        workflows: rebindWorkflows("⌥a to ←", "⌥w to ↑", "⌥d to →", "⌥s to ↓")
      ),
      Group(
        name: "Safari",
        workflows: runWorkflows("Share website", "Save as PDF")
      )
    ]
  }

  /// Used by `GroupListCell.swift`
  func groupListCell() -> Group {
    Group(
      name: "Developer tools",
      workflows: openWorkflows("Instruments", "Simulator", "Xcode")
    )
  }

  /// Used by `WorflowList.swift`
  func workflowList() -> [Workflow] {
    openWorkflows("Calendar", "Contacts", "Finder", "Mail", "Safari", "Xcode")
  }

  /// Used by `WorkflowListCell.swift`
  func workflowCell() -> Workflow {
    workflow()
  }

  /// Used by `WorkflowView.swift`
  func workflowDetail() -> Workflow {
    workflow()
  }

  // MARK: Private methods

  private func openWorkflows(_ applicationNames: String ...) -> [Workflow] {
    applicationNames.compactMap({
      Workflow(
        name: "Open \($0)",
        combinations: [],
        commands: [Command(name: "Open \($0)")]
      )
    })
  }

  private func runWorkflows(_ scriptNames: String ...) -> [Workflow] {
    scriptNames.compactMap({
      Workflow(
        name: "Run \($0) script",
        combinations: [],
        commands: [Command(name: "Run \($0)")])

    })
  }

  private func rebindWorkflows(_ scriptNames: String ...) -> [Workflow] {
    scriptNames.compactMap({
      Workflow(
        name: "Rebind \($0)",
        combinations: [],
        commands: [Command(name: "Rebind \($0)")])

    })
  }

  private func openCommands(_ commands: String ...) -> [Command] {
    commands.compactMap({ Command(name: "Open \($0)") })
  }

  private func workflow() -> Workflow {
    Workflow(
      name: "Developer workflow",
      combinations: [],
      commands: openCommands("Xcode", "Instruments", "Simulator", "Terminal")
    )
  }
}
