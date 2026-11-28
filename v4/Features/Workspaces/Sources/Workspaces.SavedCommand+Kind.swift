import WindowTidyFeature

public extension Workspaces.SavedCommand {
  enum Kind: Codable, Hashable, Sendable {
    case workspace(command: Workspaces.SavedWorkspace)
    case activatePreviousWorkspace(command: Previous)
    case assignToWorkspace(command: Assignment)
    case moveToWorkspace(command: Move)
    case appFocus(command: AppFocus)
    case tidy(command: WindowTidy.Request)
  }

  struct Previous: Codable, Hashable, Sendable {
    public let id: String

    public init(id: String) {
      self.id = id
    }
  }

  struct Assignment: Codable, Hashable, Sendable {
    public let id: String
    public let workspaceID: String

    public init(id: String, workspaceID: String) {
      self.id = id
      self.workspaceID = workspaceID
    }
  }

  struct Move: Codable, Hashable, Sendable {
    public let id: String
    public let workspace: Workspaces.SavedWorkspace

    public init(id: String, workspace: Workspaces.SavedWorkspace) {
      self.id = id
      self.workspace = workspace
    }
  }
}
