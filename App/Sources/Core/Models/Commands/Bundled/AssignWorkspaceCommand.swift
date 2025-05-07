import Apps
import AppKit
import Combine

struct AssignWorkspaceCommand: Identifiable, Hashable, Codable {
  let id: String
  let workspaceID: WorkspaceCommand.ID
}

struct MoveToWorkspaceCommand: Identifiable, Hashable, Codable {
  let id: String
  let workspace: WorkspaceCommand
}


@MainActor
final class DynamicWorkspace {
  private var assigned: [WorkspaceCommand.ID: [Application]] = [:]
  private var subscription: AnyCancellable?


  static let shared = DynamicWorkspace()

  private init() {
    let terminationPublisher = NSWorkspace.shared.notificationCenter
      .publisher(for: NSWorkspace.didTerminateApplicationNotification)

    subscription = terminationPublisher.sink { [weak self] notification in
      guard let self,
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
      self.remove(app)
    }
  }

  func applications(for workspace: WorkspaceCommand.ID) -> [Application] {
    assigned[workspace] ?? []
  }

  func assign(application: Application, using command: AssignWorkspaceCommand) async {
    if var copy = assigned[command.workspaceID] {
      copy.append(application)
      assigned[command.workspaceID] = copy
    } else {
      assigned[command.workspaceID] = [application]
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
    await assign(application: application, using: AssignWorkspaceCommand(id: command.id, workspaceID: command.workspace.id))
  }

  private func remove(_ app: RunningApplication) {
    for (id, applications) in self.assigned {
      let newApplications = applications.filter { $0.bundleIdentifier != app.bundleIdentifier }
      self.assigned[id] = newApplications.isEmpty ? nil : newApplications
    }
  }
}
