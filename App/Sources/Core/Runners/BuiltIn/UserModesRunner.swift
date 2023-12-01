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
    let output: String
    var userModes = UserSpace.shared.userModes

    guard let index = userModes.firstIndex(where: { $0.id == model.id }) else {
      throw UserModesRunnerError.unableToResolveMode
    }

    var modifiedMode = userModes[index]
    switch action {
    case .enable:
      modifiedMode.isEnabled = true
      output = "Enable: \(model.name)"
    case .disable:
      modifiedMode.isEnabled = false
      output = "Disable: \(model.name)"
    case .toggle:
      modifiedMode.isEnabled.toggle()
      output = "\(modifiedMode.name): \( modifiedMode.isEnabled ? "✅" : "⏸️")"
    }
    userModes[index] = modifiedMode
    await UserSpace.shared.setUserModes(userModes)

    return output
  }
}
