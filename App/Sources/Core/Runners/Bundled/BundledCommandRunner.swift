import AppKit
import Foundation
import MachPort

actor BundledCommandRunner: Sendable {
  static let slowApps: Set<String> = [
    "com.apple.news",
    "com.apple.maps",
  ]

  let applicationStore: ApplicationStore
  let windowFocusRunner: WindowCommandFocusRunner
  let windowTidy: WindowTidyRunner

  var detachedTask: Task<Void, any Error>?

  init(applicationStore: ApplicationStore, windowFocusRunner: WindowCommandFocusRunner, windowTidy: WindowTidyRunner) {
    self.applicationStore = applicationStore
    self.windowFocusRunner = windowFocusRunner
    self.windowTidy = windowTidy
  }

  func run(bundledCommand: BundledCommand,
           command: Command,
           commandRunner: CommandRunner,
           snapshot: inout UserSpace.Snapshot,
           machPortEvent: MachPortEvent,
           checkCancellation: Bool, repeatingEvent: Bool,
           runtimeDictionary: inout [String: String]) async throws -> String
  {
    detachedTask?.cancel()

    let output: String
    switch bundledCommand.kind {
    case .activatePreviousWorkspace:
      if let previousWorkspace = await UserSpace.shared.previousWorkspace {
        await PeekApplicationPlugin.set(machPortEvent)
        try await run(workspaceCommand: previousWorkspace,
                      forceDisableTiling: true,
                      onlyUnhide: true,
                      commandRunner: commandRunner,
                      snapshot: &snapshot,
                      machPortEvent: machPortEvent,
                      checkCancellation: checkCancellation,
                      repeatingEvent: repeatingEvent,
                      runtimeDictionary: &runtimeDictionary)
        output = "Back to \(command.name)"
      } else {
        output = ""
      }
    case let .assignToWorkspace(assignCommand):
      let currentApplication = await UserSpace.shared.frontmostApplication.asApplication()
      await DynamicWorkspace.shared.assign(application: currentApplication,
                                           using: assignCommand)
      output = "Assign \(currentApplication.displayName) to \(command.name)"
    case let .moveToWorkspace(workspaceCommand):
      let application = await UserSpace.shared.frontmostApplication
      let movedToWorkspace = await DynamicWorkspace.shared.moveOrRemove(
        application: application.asApplication(),
        using: workspaceCommand
      )
      try await run(workspaceCommand: workspaceCommand.workspace,
                    forceDisableTiling: false,
                    onlyUnhide: false,
                    commandRunner: commandRunner,
                    snapshot: &snapshot,
                    machPortEvent: machPortEvent,
                    checkCancellation: checkCancellation,
                    repeatingEvent: repeatingEvent,
                    runtimeDictionary: &runtimeDictionary)

      if movedToWorkspace {
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: application.bundleIdentifier).first {
          if #available(macOS 14.0, *) {
            runningApp.activate(from: NSWorkspace.shared.frontmostApplication!,
                                options: .activateIgnoringOtherApps)
          } else {
            runningApp.activate(options: .activateIgnoringOtherApps)
          }
        }
      }
      output = ""
    case let .appFocus(focusCommand):
      let applications = applicationStore.applications
      let commands = try await focusCommand.commands(applications, checkCancellation: checkCancellation)
      for command in commands {
        try Task.checkCancellation()
        switch command {
        case let .windowTiling(tilingCommand):
          try await WindowTilingRunner.run(tilingCommand.kind, toggleFill: false, snapshot: snapshot)
        default:
          try await commandRunner
            .run(command,
                 workflowCommands: commands,
                 snapshot: &snapshot,
                 machPortEvent: machPortEvent,
                 checkCancellation: checkCancellation,
                 repeatingEvent: repeatingEvent,
                 runtimeDictionary: &runtimeDictionary)
        }

        if let delay = command.delay, delay > 0 {
          try? await Task.sleep(for: .milliseconds(delay))
        }
      }
      await windowFocusRunner.resetFocusComponents()
      Task.detached {
        try await Task.sleep(for: .milliseconds(375))
        WindowTilingRunner.index()
      }
      output = command.name
    case let .workspace(workspaceCommand):
      let runningBundleIdentifiers = workspaceCommand.bundleIdentifiers.flatMap { bundleIdentifier in
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
          .compactMap(\.bundleIdentifier)
      }
      let onlyUnhide: Bool
      let requiredBundleIdentifiers: Set<String> = Set(workspaceCommand.bundleIdentifiers)
      let allRunning = requiredBundleIdentifiers.isSubset(of: runningBundleIdentifiers)
      onlyUnhide = allRunning

      try await run(workspaceCommand: workspaceCommand,
                    forceDisableTiling: false,
                    onlyUnhide: onlyUnhide,
                    commandRunner: commandRunner,
                    snapshot: &snapshot,
                    machPortEvent: machPortEvent,
                    checkCancellation: checkCancellation,
                    repeatingEvent: repeatingEvent,
                    runtimeDictionary: &runtimeDictionary)
      output = command.name
    case let .tidy(command):
      try await windowTidy.run(command)
      output = bundledCommand.name
    }
    return output
  }

  private func run(workspaceCommand: WorkspaceCommand,
                   forceDisableTiling: Bool,
                   onlyUnhide: Bool,
                   commandRunner: CommandRunner,
                   snapshot: inout UserSpace.Snapshot,
                   machPortEvent: MachPortEvent,
                   checkCancellation: Bool, repeatingEvent: Bool,
                   runtimeDictionary: inout [String: String]) async throws
  {
    let applications = applicationStore.applications
    let dynamicApps = await DynamicWorkspace.shared
      .applications(for: workspaceCommand.id)
      .filter { !workspaceCommand.bundleIdentifiers.contains($0.bundleIdentifier) }
    await MainActor.run {
      let previousWorkspace = UserSpace.shared.currentWorkspace
      if let previousWorkspace, previousWorkspace.id != workspaceCommand.id {
        UserSpace.shared.previousWorkspace = previousWorkspace
      } else if workspaceCommand.id != previousWorkspace?.id {
        UserSpace.shared.previousWorkspace = previousWorkspace
      }
      UserSpace.shared.currentWorkspace = workspaceCommand
    }

    let result = try await workspaceCommand.commands(applications, dynamicApps: dynamicApps)
    var commands = result

    if UserSettings.WindowManager.stageManagerEnabled && result.isEmpty {
      await CapsuleNotificationWindow.shared
        .open()
        .publish("No application assigned to workspace", id: UUID().uuidString, state: .warning)

      return
    }

    // This should only be true if it comes from `activatePreviousWorkspace`.
    // It is set to true in order to keep the last focused application the same as when the
    // workspace was previously active.
    let dynamicWorkspaceWithoutTiling = (workspaceCommand.isDynamic && workspaceCommand.tiling == nil)
    if onlyUnhide || dynamicWorkspaceWithoutTiling {
      if workspaceCommand.bundleIdentifiers.count > 1 {
        commands = handleOnlyUnhide(commands, dynamicWorkspaceWithoutTiling: dynamicWorkspaceWithoutTiling)
      }
    }

    for (offset, command) in commands.enumerated() {
      do {
        try Task.checkCancellation()
      } catch {
        await windowFocusRunner.resetFocusComponents()
        throw error
      }
      switch command {
      case let .windowTiling(tilingCommand):
        if !forceDisableTiling {
          try await WindowTilingRunner.run(tilingCommand.kind, toggleFill: false, snapshot: snapshot)
          continue
        }
      default:
        var checkCancellation = checkCancellation
        if case let .application(appCommand) = command {
          if appCommand.modifiers.contains(.waitForAppToLaunch) {
            checkCancellation = false
          }
        }

        if case let .application(applicationCommand) = command,
           applicationCommand.action == .open,
           offset == 0,
           Self.slowApps.contains(applicationCommand.application.bundleIdentifier.lowercased())
        {
          detachedTask = Task.detached { [commandRunner, snapshot, runtimeDictionary] in
            var snapshot = snapshot
            var runtimeDictionary = runtimeDictionary
            try await commandRunner
              .run(command,
                   workflowCommands: commands,
                   snapshot: &snapshot,
                   machPortEvent: machPortEvent,
                   checkCancellation: true,
                   repeatingEvent: repeatingEvent,
                   runtimeDictionary: &runtimeDictionary)
          }
        } else {
          var snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false)
          var runtimeDictionary = [String: String]()
          try await commandRunner
            .run(command,
                 workflowCommands: commands,
                 snapshot: &snapshot,
                 machPortEvent: machPortEvent,
                 checkCancellation: checkCancellation,
                 repeatingEvent: repeatingEvent,
                 runtimeDictionary: &runtimeDictionary)
        }
      }

      if let delay = command.delay, delay > 0 {
        try? await Task.sleep(for: .milliseconds(delay))
      }

      if offset == commands.count - 1 {
        let currentBundleIdentifier: Set<String> = [NSWorkspace.shared.frontmostApplication!.bundleIdentifier!]
        let commmandBundleIdentifiers: Set<String> = Set(workspaceCommand.bundleIdentifiers + dynamicApps.map(\.bundleIdentifier))

        if currentBundleIdentifier != commmandBundleIdentifiers {
          await windowFocusRunner.resetFocusComponents()
        }

        let shouldActivateTopApp = !currentBundleIdentifier.isSubset(of: commmandBundleIdentifiers)
        let validPids = Set(commmandBundleIdentifiers.flatMap {
          NSRunningApplication.runningApplications(withBundleIdentifier: $0).map(\.processIdentifier)
        })

        let newSnapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: false, refreshWindows: true)
        if shouldActivateTopApp, let firstWindow = newSnapshot.windows.visibleWindowsInStage.first(where: {
          validPids.contains(pid_t($0.ownerPid.rawValue))
        }),
          let runningApp = NSRunningApplication(processIdentifier: pid_t(firstWindow.ownerPid.rawValue))
        {
          if #available(macOS 14.0, *) {
            runningApp.activate(from: NSWorkspace.shared.frontmostApplication!, options: .activateIgnoringOtherApps)
          } else {
            runningApp.activate(options: .activateIgnoringOtherApps)
          }
        }
      }
    }

    await windowFocusRunner.resetFocusComponents()

    Task.detached {
      try await Task.sleep(for: .milliseconds(375))
      WindowTilingRunner.index()
    }
  }

  private func handleOnlyUnhide(_ commands: [Command], dynamicWorkspaceWithoutTiling: Bool) -> [Command] {
    var commands = commands
    let indexOfLast = commands.lastIndex(where: {
      if case .application = $0 { return true }
      return false
    })

    for (offset, command) in commands.enumerated() {
      if case var .application(applicationCommand) = command {
        if dynamicWorkspaceWithoutTiling {
          applicationCommand.delay = nil
          applicationCommand.action = offset == indexOfLast ? .open : .unhide
        } else {
          applicationCommand.action = .unhide
        }

        commands[offset] = .application(applicationCommand)
      }
    }
    return commands
  }
}
