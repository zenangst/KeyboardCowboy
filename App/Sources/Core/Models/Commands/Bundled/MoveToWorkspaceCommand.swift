struct MoveToWorkspaceCommand: Identifiable, Hashable, Codable {
  let id: String
  let workspace: WorkspaceCommand
}
