import Foundation

class ModelFactory {

  // MARK: Public methods

  /// Used by `GroupList.swift`
  func groupList() -> [GroupViewModel] {
    [
      GroupViewModel(
        id: UUID().uuidString,
        name: "Applications",
        color: "#EB5545",
        workflows: openWorkflows("Calendar", "Contacts", "Finder", "Mail", "Safari", "Xcode")
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Developer tools",
        color: "#F2A23C",
        workflows: openWorkflows("Instruments", "Simulator", "Xcode")
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Folders",
        color: "#F9D64A",
        workflows: openWorkflows("Home folder", "Developer folder")
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Files",
        color: "#6BD35F",
        workflows: openWorkflows(".gitconfig", "Design project.sketch", "Keyboard-Cowboy.xcodeproj")
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Keyboard shortcuts",
        color: "#3984F7",
        workflows: rebindWorkflows("⌥a to ←", "⌥w to ↑", "⌥d to →", "⌥s to ↓")
      ),
      GroupViewModel(
        id: UUID().uuidString,
        name: "Safari",
        color: "#B263EA",
        workflows: runWorkflows("Share website", "Save as PDF")
      )
    ]
  }

  /// Used by `GroupListCell.swift`
  func groupListCell() -> GroupViewModel {
    GroupViewModel(
      id: UUID().uuidString,
      name: "Developer tools",
      color: "#000",
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
        id: UUID().uuidString,
        name: "Open \($0)",
        combinations: [],
        commands: [CommandViewModel(name: "Open \($0)")]
      )
    })
  }

  private func runWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        id: UUID().uuidString,
        name: "Run \($0) script",
        combinations: [],
        commands: [CommandViewModel(name: "Run \($0)")])

    })
  }

  private func rebindWorkflows(_ scriptNames: String ...) -> [WorkflowViewModel] {
    scriptNames.compactMap({
      WorkflowViewModel(
        id: UUID().uuidString,
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
      id: UUID().uuidString,
      name: "Developer workflow",
      combinations: [],
      commands: openCommands("Xcode", "Instruments", "Simulator", "Terminal")
    )
  }
}
