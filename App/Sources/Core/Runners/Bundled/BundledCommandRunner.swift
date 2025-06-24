import Foundation
import AppKit
import MachPort

final class BundledCommandRunner: Sendable {
  let applicationStore: ApplicationStore
  let windowFocusRunner: WindowCommandFocusRunner
  let windowTidy: WindowTidyRunner

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
           runtimeDictionary: inout [String: String]) async throws -> String {
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
    case .assignToWorkspace(let assignCommand):
      let currentApplication = await UserSpace.shared.frontmostApplication.asApplication()
      await DynamicWorkspace.shared.assign(application: currentApplication,
                                           using: assignCommand)
      output = "Assign \(currentApplication.displayName) to \(command.name)"
    case .moveToWorkspace(let workspaceCommand):
      let application = await UserSpace.shared.frontmostApplication
      let movedToWorkspace = await DynamicWorkspace.shared.moveOrRemove(
        application: application.asApplication(),
        using: workspaceCommand)
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
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
          if #available(macOS 14.0, *) {
            runningApp.activate(from: NSWorkspace.shared.frontmostApplication!,
                                options: .activateIgnoringOtherApps
            )
          } else {
            runningApp.activate(options: .activateIgnoringOtherApps)
          }
        }
      }
      output = ""
    case .appFocus(let focusCommand):
      let applications = applicationStore.applications
      let commands = try await focusCommand.commands(applications, checkCancellation: checkCancellation)
      for command in commands {
        try Task.checkCancellation()
        switch command {
        case .windowTiling(let tilingCommand):
          try await WindowTilingRunner.run(tilingCommand.kind, toggleFill: false, snapshot: snapshot)
        default:
          try await commandRunner
            .run(command,
                 workflowCommands: commands,
                 snapshot: &snapshot,
                 machPortEvent: machPortEvent,
                 checkCancellation: checkCancellation,
                 repeatingEvent: repeatingEvent,
                 runtimeDictionary: &runtimeDictionary
          )
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
    case .workspace(let workspaceCommand):
      try await run(workspaceCommand: workspaceCommand,
                    forceDisableTiling: false,
                    onlyUnhide: false,
                    commandRunner: commandRunner,
                    snapshot: &snapshot,
                    machPortEvent: machPortEvent,
                    checkCancellation: checkCancellation,
                    repeatingEvent: repeatingEvent,
                    runtimeDictionary: &runtimeDictionary)
      output = command.name
    case .tidy(let command):
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
                   runtimeDictionary: inout [String: String]) async throws {
    let applications = applicationStore.applications
    let dynamicApps = await DynamicWorkspace.shared.applications(for: workspaceCommand.id)
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

    var commands = try await workspaceCommand.commands(applications, dynamicApps: dynamicApps)
    // This should only be true if it comes from `activatePreviousWorkspace`.
    // It is set to true in order to keep the last focused application the same as when the
    // workspace was previously active.
    let dynamicWorkspaceWithoutTiling = (workspaceCommand.isDynamic && workspaceCommand.tiling == nil)
    if onlyUnhide || dynamicWorkspaceWithoutTiling {
      if workspaceCommand.bundleIdentifiers.count > 1 {
        commands = handleOnlyUnhide(commands, dynamicWorkspaceWithoutTiling: dynamicWorkspaceWithoutTiling)
      }
    }

    for command in commands {
      do {
        try Task.checkCancellation()
      } catch {
        await windowFocusRunner.resetFocusComponents()
        throw error
      }
      switch command {
      case .windowTiling(let tilingCommand):
        if !forceDisableTiling {
          try await WindowTilingRunner.run(tilingCommand.kind, toggleFill: false, snapshot: snapshot)
          continue
        }
      default:
        var checkCancellation = checkCancellation
        if case .application(let appCommand) = command {
          if appCommand.modifiers.contains(.waitForAppToLaunch) {
            checkCancellation = false
          }
        }

        try await commandRunner
          .run(command,
               workflowCommands: commands,
               snapshot: &snapshot,
               machPortEvent: machPortEvent,
               checkCancellation: checkCancellation,
               repeatingEvent: repeatingEvent,
               runtimeDictionary: &runtimeDictionary
          )
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
  }

  private func handleOnlyUnhide(_ commands: [Command], dynamicWorkspaceWithoutTiling: Bool) -> [Command] {
    var commands = commands
    let indexOfLast = commands.lastIndex(where: {
      if case .application = $0 { return true }
      return false
    })

    for (offset, command) in commands.enumerated() {
      if case .application(var applicationCommand) = command {
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
