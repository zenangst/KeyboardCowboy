import Foundation
import MachPort

final class BuiltInCommandRunner {
  let commandLine: CommandLineCoordinator
  let configurationStore: ConfigurationStore
  let macroRunner: MacroRunner
  let repeatLastWorkflowRunner: RepeatLastWorkflowRunner

  init(commandLine: CommandLineCoordinator,
       configurationStore: ConfigurationStore,
       macroRunner: MacroRunner,
       repeatLastWorkflowRunner: RepeatLastWorkflowRunner) {
    self.commandLine = commandLine
    self.configurationStore = configurationStore
    self.macroRunner = macroRunner
    self.repeatLastWorkflowRunner = repeatLastWorkflowRunner
  }

  func run(_ command: BuiltInCommand, 
           shortcut: KeyShortcut,
           machPortEvent: MachPortEvent) async throws -> String {
    return switch command.kind {
    case .macro(let action):
      await macroRunner
        .run(action, shortcut: shortcut, machPortEvent: machPortEvent)
    case .userMode(let model, let action):
      try await UserModesRunner(configurationStore: configurationStore)
        .run(model, builtInCommand: command, action: action)
    case .commandLine(let action):
      await commandLine.show(action)
    case .repeatLastWorkflow:
      try await repeatLastWorkflowRunner.run()
    }
  }
}
