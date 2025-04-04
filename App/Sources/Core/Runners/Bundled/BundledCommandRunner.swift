import Foundation
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
           snapshot: UserSpace.Snapshot,
           machPortEvent: MachPortEvent,
           checkCancellation: Bool, repeatingEvent: Bool,
           runtimeDictionary: inout [String: String]) async throws -> String {
    let output: String
    switch bundledCommand.kind {
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
                 snapshot: snapshot,
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
        WindowTilingRunner.initialIndex()
      }
      output = command.name
    case .workspace(let workspaceCommand):
      let applications = applicationStore.applications
      let commands = try await workspaceCommand.commands(applications)
      for command in commands {
        try Task.checkCancellation()
        switch command {
        case .windowTiling(let tilingCommand):
          try await WindowTilingRunner.run(tilingCommand.kind, toggleFill: false, snapshot: snapshot)
        default:
          try await commandRunner
            .run(command,
                 workflowCommands: commands,
                 snapshot: snapshot,
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
      WindowTilingRunner.initialIndex()
      output = command.name
    case .tidy(let command):
      try await windowTidy.run(command)
      output = bundledCommand.name
    }
    return output
  }
}
