import Foundation

enum UserModesRunnerError: Error {
  case unableToResolveMode
}

final class UserModesRunner {
  let configurationStore: ConfigurationStore

  init(configurationStore: ConfigurationStore) {
    self.configurationStore = configurationStore
  }

  func run(_ model: UserMode, builtInCommand: BuiltInCommand, action: BuiltInCommand.Kind.Action) async throws -> String {
    Benchmark.shared.start("UserModesRunner")
    let output: String
    var userModes = await UserSpace.shared.currentUserModes

    guard let index = userModes.firstIndex(where: { $0.id == model.id }) else {
      throw UserModesRunnerError.unableToResolveMode
    }

    var modifiedMode = userModes[index]
    switch action {
    case .enable:
      modifiedMode.isEnabled = true
      output = "\(builtInCommand.name) ✅"
    case .disable:
      modifiedMode.isEnabled = false
      output = "\(builtInCommand.name) ⏸️"
    case .toggle:
      modifiedMode.isEnabled.toggle()
      output = "\(builtInCommand.name): \( modifiedMode.isEnabled ? "✅" : "⏸️")"
    }
    userModes[index] = modifiedMode
    await UserSpace.shared.setUserModes(userModes)

    Benchmark.shared.stop("UserModesRunner")

    return output
  }
}
