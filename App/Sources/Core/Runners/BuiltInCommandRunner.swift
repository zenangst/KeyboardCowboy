import Foundation

final class BuiltInCommandRunner {
  let configurationStore: ConfigurationStore

  init(configurationStore: ConfigurationStore) {
    self.configurationStore = configurationStore
  }

  func run(_ command: BuiltInCommand) async throws -> String {
    return switch command.kind {
    case .userMode(let model, let action): try await UserModesRunner(
      configurationStore: configurationStore
    )
    .run(model, builtInCommand: command, action: action)
    }
  }
}
