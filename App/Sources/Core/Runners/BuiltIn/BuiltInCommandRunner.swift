import Foundation
import MachPort

final class BuiltInCommandRunner: Sendable {
  let commandLine: CommandLineCoordinator
  let configurationStore: ConfigurationStore
  let macroRunner: MacroRunner
  let repeatLastWorkflowRunner: RepeatLastWorkflowRunner
  let windowSwitcher: WindowSwitcherRunner

  init(commandLine: CommandLineCoordinator,
       configurationStore: ConfigurationStore,
       macroRunner: MacroRunner,
       repeatLastWorkflowRunner: RepeatLastWorkflowRunner,
       windowOpener: WindowOpener)
  {
    self.commandLine = commandLine
    self.configurationStore = configurationStore
    self.macroRunner = macroRunner
    self.repeatLastWorkflowRunner = repeatLastWorkflowRunner
    windowSwitcher = WindowSwitcherRunner(windowOpener)
  }

  func run(_ command: BuiltInCommand, snapshot: UserSpace.Snapshot, machPortEvent: MachPortEvent) async throws -> String {
    switch command.kind {
    case let .macro(action):
      await macroRunner.run(action, machPortEvent: machPortEvent)
    case let .userMode(model, action):
      try await UserModesRunner(configurationStore: configurationStore)
        .run(model, builtInCommand: command, action: action)
    case let .commandLine(action):
      await commandLine.show(action)
    case .repeatLastWorkflow:
      try await repeatLastWorkflowRunner.run()
    case .windowSwitcher:
      await windowSwitcher.run(snapshot)
    }
  }
}
