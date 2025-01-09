import Foundation
import MachPort

final class BundledCommandRunner {
  let applicationStore: ApplicationStore
  let systemRunner: SystemCommandRunner

  init(applicationStore: ApplicationStore, systemRunner: SystemCommandRunner) {
    self.applicationStore = applicationStore
    self.systemRunner = systemRunner
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
      let commands = try await focusCommand.commands(applications)
      for command in commands {
        try Task.checkCancellation()
        switch command {
        case .systemCommand(let systemCommand):
          switch systemCommand.kind {
          case .windowTilingArrangeLeftRight:
            try await SystemWindowTilingRunner.run(.arrangeLeftRight, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeRightLeft:
            try await SystemWindowTilingRunner.run(.arrangeRightLeft, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeTopBottom:
            try await SystemWindowTilingRunner.run(.arrangeTopBottom, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeBottomTop:
            try await SystemWindowTilingRunner.run(.arrangeBottomTop, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeLeftQuarters:
            try await SystemWindowTilingRunner.run(.arrangeLeftQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeRightQuarters:
            try await SystemWindowTilingRunner.run(.arrangeRightQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeTopQuarters:
            try await SystemWindowTilingRunner.run(.arrangeTopQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeBottomQuarters:
            try await SystemWindowTilingRunner.run(.arrangeBottomQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeQuarters:
            try await SystemWindowTilingRunner.run(.arrangeQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingFill:
            try await SystemWindowTilingRunner.run(.fill, toggleFill: false, snapshot: snapshot)
          case .windowTilingCenter:
            try await SystemWindowTilingRunner.run(.center, toggleFill: false, snapshot: snapshot)
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
      await systemRunner.resetFocusComponents()
      Task.detached {
        try await Task.sleep(for: .milliseconds(375))
        SystemWindowTilingRunner.initialIndex()
      }
      output = command.name
    case .workspace(let workspaceCommand):
      let applications = applicationStore.applications
      let commands = try await workspaceCommand.commands(applications)
      for command in commands {
        try Task.checkCancellation()
        switch command {
        case .systemCommand(let systemCommand):
          switch systemCommand.kind {
          case .windowTilingArrangeLeftRight:
            try await SystemWindowTilingRunner.run(.arrangeLeftRight, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeRightLeft:
            try await SystemWindowTilingRunner.run(.arrangeRightLeft, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeTopBottom:
            try await SystemWindowTilingRunner.run(.arrangeTopBottom, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeBottomTop:
            try await SystemWindowTilingRunner.run(.arrangeBottomTop, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeLeftQuarters:
            try await SystemWindowTilingRunner.run(.arrangeLeftQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeRightQuarters:
            try await SystemWindowTilingRunner.run(.arrangeRightQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeTopQuarters:
            try await SystemWindowTilingRunner.run(.arrangeTopQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeBottomQuarters:
            try await SystemWindowTilingRunner.run(.arrangeBottomQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingArrangeQuarters:
            try await SystemWindowTilingRunner.run(.arrangeQuarters, toggleFill: false, snapshot: snapshot)
          case .windowTilingFill:
            try await SystemWindowTilingRunner.run(.fill, toggleFill: false, snapshot: snapshot)
          case .windowTilingCenter:
            try await SystemWindowTilingRunner.run(.center, toggleFill: false, snapshot: snapshot)
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
      await systemRunner.resetFocusComponents()
      SystemWindowTilingRunner.initialIndex()
      output = command.name
    }
    return output
  }
}
