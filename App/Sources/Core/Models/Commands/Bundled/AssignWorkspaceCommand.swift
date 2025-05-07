import Apps

struct AssignWorkspaceCommand: Identifiable, Hashable, Codable {
  let id: String
  let workspace: WorkspaceCommand.ID
}

struct MoveToWorkspaceCommand: Identifiable, Hashable, Codable {
  let id: String
  let workspace: WorkspaceCommand.ID
}


@MainActor
final class DynamicWorkspace {
  var assigned: [WorkspaceCommand.ID: [Application]] = [:]

  static let shared = DynamicWorkspace()

  private init() { }

  func applications(for workspace: WorkspaceCommand.ID) -> [Application] {
    assigned[workspace] ?? []
  }

  func assign(application: Application, using command: AssignWorkspaceCommand) async {
    if var copy = assigned[command.workspace] {
      copy.append(application)
      assigned[command.workspace] = copy
    } else {
      assigned[command.workspace] = [application]
    }
  }

  func move(application: Application, using command: MoveToWorkspaceCommand) async {
    for (id, applications) in assigned {
      var applications = applications
      if applications.contains(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
        applications.removeAll(where: { $0.bundleIdentifier == application.bundleIdentifier })
        assigned[id] = applications
      }
    }
    await assign(application: application, using: AssignWorkspaceCommand(id: command.id, workspace: command.workspace))
  }
}
