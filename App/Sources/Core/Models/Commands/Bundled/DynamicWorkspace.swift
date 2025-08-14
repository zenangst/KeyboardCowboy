import Apps
import Cocoa
import Combine
import Windows

@MainActor
final class DynamicWorkspace {
  private var assigned: [WorkspaceCommand.ID: [Application]] = [:]
  private var subscriptions = [AnyCancellable]()

  static let shared = DynamicWorkspace()

  private init() {
    let launchPublisher = NSWorkspace.shared
      .notificationCenter
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

          let newCommand = AssignWorkspaceCommand(id: UUID().uuidString, workspaceID: currentWorkspace.id)
          await self.assign(application: application, using: newCommand)
        }
      }
      .store(in: &subscriptions)

    NSWorkspace.shared
      .publisher(for: \.frontmostApplication)
      .sink { [weak self] runningApplication in
        guard let self, let bundleIdentifier = runningApplication?.bundleIdentifier else { return }

        self.removeClosedApps()
        self.reorderCurrentWorkspace(bundleIdentifier)
      }
      .store(in: &subscriptions)
  }

  func applications(for workspace: WorkspaceCommand.ID) -> [Application] {
    assigned[workspace] ?? []
  }

  func assign(application: Application, using command: AssignWorkspaceCommand) async {
    if !UserSettings.WindowManager.stageManagerEnabled, var copy = assigned[command.workspaceID] {
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
    var wasAlreadyMember = false
    for (id, applications) in assigned {
      var newApplications = applications
      if newApplications.contains(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
        if command.workspace.id == id {
          wasAlreadyMember = true
        }

        // Disable removing dynamic workspace applications when stage manager is enabled.
        if !UserSettings.WindowManager.stageManagerEnabled, newApplications.count > 1 {
          newApplications.removeAll(where: { $0.bundleIdentifier == application.bundleIdentifier })
        }

        assigned[id] = newApplications
      }
    }

    if !wasAlreadyMember {
      await assign(application: application, using: AssignWorkspaceCommand(command))
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
                                     onCreate: (_ key: String, _ match: KeyboardShortcutResult) -> Void)
  {
    let workspaces = workflow.commands.compactMap {
      if case let .bundled(command) = $0,
         case let .workspace(workspace) = command.kind
      {
        if UserSpace.shared.currentWorkspace == nil, workspace.defaultForDynamicWorkspace {
          assignAppsToDefaultDynamicWorkspace(workspace)
        }
        return workspace
      } else {
        return nil
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
            ),
          ]
        )
        onCreate(key, .exact(workflow))
      }
    }
  }

  // MARK: - Private methods

  private static func assignAppsToDefaultDynamicWorkspace(_ workspace: WorkspaceCommand) {
    UserSpace.shared.currentWorkspace = workspace

    let pids = Set(
      indexWindowsInStage(getWindows([.optionOnScreenOnly, .excludeDesktopElements]))
        .map { pid_t($0.ownerPid.rawValue) }
    )
    let excludedBundleIdentifiers: Set<String> = ["com.apple.finder"]
    let bundleUrls = NSWorkspace.shared
      .runningApplications
      .filter {
        guard let bundleIdentifier = $0.bundleIdentifier else {
          return false
        }

        if excludedBundleIdentifiers.contains(bundleIdentifier) {
          return false
        }
        return pids.contains($0.processIdentifier)
      }
      .compactMap(\.bundleURL)

    for bundleUrl in bundleUrls {
      guard let application = ApplicationStore.shared.application(at: bundleUrl) else {
        continue
      }

      Task {
        await DynamicWorkspace.shared.assign(
          application: application,
          using: AssignWorkspaceCommand(
            id: UUID().uuidString,
            workspaceID: workspace.id
          )
        )
      }
    }
  }

  private func removeClosedApps() {
    for (_, applications) in assigned {
      for app in applications {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
        if runningApps.isEmpty {
          remove(app)
          continue
        }

        for runningApp in runningApps where runningApp.isTerminated {
          remove(app)
        }
      }
    }
  }

  private func reorderCurrentWorkspace(_ bundleIdentifier: String) {
    guard
      let currentWorkspaceId = UserSpace.shared.currentWorkspace?.id,
      var applications = assigned[currentWorkspaceId],
      !applications.isEmpty,
      let index = applications.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) else { return }

    applications.append(applications.remove(at: index))

    assigned[currentWorkspaceId] = applications
  }

  private func remove(_ app: RunningApplication) {
    for (id, applications) in assigned {
      let newApplications = applications.filter { $0.bundleIdentifier != app.bundleIdentifier }
      assigned[id] = newApplications.isEmpty ? nil : newApplications
    }
  }

  private func remove(_ app: Application) {
    for (id, applications) in assigned {
      let newApplications = applications.filter { $0.bundleIdentifier != app.bundleIdentifier }
      assigned[id] = newApplications.isEmpty ? nil : newApplications
    }
  }

  private static func getWindows(_ options: CGWindowListOption) -> [WindowModel] {
    let windowModels: [WindowModel] = ((try? WindowsInfo.getWindows(options)) ?? [])
    return windowModels
  }

  private static func indexWindowsInStage(_ models: [WindowModel]) -> [WindowModel] {
    let excluded = ["WindowManager", "Window Server"]
    let minimumSize = CGSize(width: 300, height: 200)
    let windows: [WindowModel] = models
      .filter {
        $0.id > 0 &&
          $0.ownerName != "borders" &&
          $0.rect.size.width > minimumSize.width &&
          $0.rect.size.height > minimumSize.height &&
          $0.alpha == 1 &&
          !excluded.contains($0.ownerName)
      }

    return windows
  }
}

extension AssignWorkspaceCommand {
  init(_ moveToWorkspace: MoveToWorkspaceCommand) {
    id = moveToWorkspace.id
    workspaceID = moveToWorkspace.workspace.id
  }
}
