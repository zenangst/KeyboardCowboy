struct AssignWorkspaceCommand: Identifiable, Hashable, Codable {
  let id: String
  let workspaceID: WorkspaceCommand.ID
}
