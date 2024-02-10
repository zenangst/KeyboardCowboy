import Foundation

final class BuiltInCommandRunner {
  let configurationStore: ConfigurationStore
  let macroRunner: MacroRunner

  init(configurationStore: ConfigurationStore,
       macroRunner: MacroRunner) {
    self.configurationStore = configurationStore
    self.macroRunner = macroRunner
  }

  func run(_ command: BuiltInCommand) async throws -> String {
    return switch command.kind {
      case .macro(let action):
        await macroRunner.run(action)
      case .userMode(let model, let action): try await UserModesRunner(
        configurationStore: configurationStore
      )
      .run(model, builtInCommand: command, action: action)
    }
  }
}
