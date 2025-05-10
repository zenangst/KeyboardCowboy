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
  private var subscriptions = [AnyCancellable]()

  static let shared = DynamicWorkspace()

  private init() {
    let terminationPublisher = NSWorkspace.shared.notificationCenter
      .publisher(for: NSWorkspace.didTerminateApplicationNotification)
    let launchPublisher = NSWorkspace.shared.notificationCenter
      .publisher(for: NSWorkspace.didLaunchApplicationNotification)

    launchPublisher
      .sink { [weak self] notification in
        Task { @MainActor in
          guard
            let self,
            let currentWorkspace = UserSpace.shared.currentWorkspace,
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundleIdentifier = app.bundleIdentifier,
            let application = ApplicationStore.shared.application(for: bundleIdentifier) else { return }

          let hasAssignmentKeys = !currentWorkspace.appToggleModifiers.isEmpty
          let isDynamicWorkspace = hasAssignmentKeys && currentWorkspace.bundleIdentifiers.isEmpty

          guard isDynamicWorkspace else { return }

          await self.assign(application: application, using: .init(id: UUID().uuidString, workspaceID: currentWorkspace.id))
        }
      }
      .store(in: &subscriptions)

    terminationPublisher
      .sink { [weak self] notification in
      guard let self,
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
      self.remove(app)
    }
    .store(in: &subscriptions)
  }

  func applications(for workspace: WorkspaceCommand.ID) -> [Application] {
    assigned[workspace] ?? []
  }

  func assign(application: Application, using command: AssignWorkspaceCommand) async {
    if var copy = assigned[command.workspaceID] {
      copy.insert(application, at: 0)
      assigned[command.workspaceID] = copy
    } else {
      assigned[command.workspaceID] = [application]
    }
  }

  /// Move or remove an application from a workspace
  /// - Parameters:
  ///   - application: The targeted `Application`
  ///   - command: The in-memory command
  /// - Returns: `true` if the `Application` was added to the Workspace, `false` if it was removed.
  func moveOrRemove(application: Application, using command: MoveToWorkspaceCommand) async -> Bool {
    var wasAlreadyMember: Bool = false
    for (id, applications) in assigned {
      var newApplications = applications
      if newApplications.contains(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
        if command.workspace.id == id {
          wasAlreadyMember = true
        }

        newApplications.removeAll(where: { $0.bundleIdentifier == application.bundleIdentifier })
        assigned[id] = newApplications
      }
    }

    if !wasAlreadyMember {
      await assign(application: application, using: AssignWorkspaceCommand(id: command.id, workspaceID: command.workspace.id))
      return true
    } else {
      return false
    }
  }

  // MARK: - Static methods

  static func createDynamicWorkflows(for workflow: Workflow,
                                      keyCode: Int64,
                                      flags: CGEventFlags,
                                      bundleIdentifier: String,
                                      userModeKey: String,
                                      previousKey: String,
                                      onCreate: (_ key: String, _ match: KeyboardShortcutResult) -> Void) {
    let workspaces = workflow.commands.compactMap {
      if case .bundled(let command) = $0,
         case .workspace(let workspace) = command.kind {
        workspace
      } else {
        nil
      }
    }
    guard let first = workspaces.first else { return }

    let appToggleModifiers = first.appToggleModifiers
    if !appToggleModifiers.isEmpty {
      for modifier in appToggleModifiers {
        var flags = flags
        flags.insert(modifier.cgEventFlags)
        let eventSignature = CGEventSignature(Int64(keyCode), flags)
        let key = ShortcutResolver.createKey(eventSignature: eventSignature,
                                             bundleIdentifier: bundleIdentifier,
                                             userModeKey: userModeKey,
                                             previousKey: previousKey)
        let workflow = Workflow(
          name: "Dynamic Workflow from \(key)",
          commands: [
            .bundled(
              BundledCommand(
                .moveToWorkspace(
                  command: MoveToWorkspaceCommand(
                    id: UUID().uuidString,
                    workspace: first
                  )
                ),
                meta: Command.MetaData()
              )
            )
          ]
        )
        onCreate(key, .exact(workflow))
      }
    }
  }

  // MARK: - Private methods

  private func remove(_ app: RunningApplication) {
    for (id, applications) in self.assigned {
      let newApplications = applications.filter { $0.bundleIdentifier != app.bundleIdentifier }
      self.assigned[id] = newApplications.isEmpty ? nil : newApplications
    }
  }
}
