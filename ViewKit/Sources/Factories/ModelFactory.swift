import Foundation

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  func groupList() -> [GroupViewModel] {
    [
      GroupViewModel(
        name: "Applications",
        workflows: openWorkflows("Calendar", "Contacts", "Finder", "Mail", "Safari", "Xcode")
      ),
      GroupViewModel(
        name: "Developer tools",
        workflows: openWorkflows("Instruments", "Simulator", "Xcode")
      ),
      GroupViewModel(
        name: "Folders",
        workflows: openWorkflows("Home folder", "Developer folder")
      ),
      GroupViewModel(
        name: "Files",
        workflows: openWorkflows(".gitconfig", "Design project.sketch", "Keyboard-Cowboy.xcodeproj")
      ),
      GroupViewModel(
        name: "Keyboard shortcuts",
        workflows: rebindWorkflows("⌥a to ←", "⌥w to ↑", "⌥d to →", "⌥s to ↓")
      ),
      GroupViewModel(
        name: "Safari",
        workflows: runWorkflows("Share website", "Save as PDF")
      )
    ]
  }

  /// Used by `GroupListCell.swift`
  func groupListCell() -> GroupViewModel {
    GroupViewModel(
      name: "Developer tools",
      workflows: openWorkflows("Instruments", "Simulator", "Xcode")
    )
  }

  /// Used by `WorflowList.swift`
  func workflowList() -> [WorkflowViewModel] {
    openWorkflows("Calendar", "Contacts", "Finder", "Mail", "Safari", "Xcode")
  }

  /// Used by `WorkflowListCell.swift`
  func workflowCell() -> WorkflowViewModel {
    workflow()
  }

  /// Used by `WorkflowView.swift`
  func workflowDetail() -> WorkflowViewModel {
    workflow()
  }

  // MARK: Private methods

  private func openWorkflows(_ applicationNames: String ...) -> [WorkflowViewModel] {
    applicationNames.compactMap({
      WorkflowViewModel(
        name: "Open \($0)",
        combinations: [],
        commands: [CommandViewModel(name: "Open \($0)")]
      )
    })
  }

  private func runWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        name: "Run \($0) script",
        combinations: [],
        commands: [CommandViewModel(name: "Run \($0)")])

    })
  }

  private func rebindWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        name: "Rebind \($0)",
        combinations: [],
        commands: [CommandViewModel(name: "Rebind \($0)")])

    })
  }

  private func openCommands(_ commands: String ...) -> [CommandViewModel] {
    commands.compactMap({ CommandViewModel(name: "Open \($0)") })
  }

  private func workflow() -> WorkflowViewModel {
    WorkflowViewModel(
      name: "Developer workflow",
      combinations: [],
      commands: openCommands("Xcode", "Instruments", "Simulator", "Terminal")
    )
  }
}
