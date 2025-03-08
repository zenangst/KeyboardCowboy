import Cocoa

final class ScriptCommandRunner: Sendable {
  private struct Plugins: Sendable {
    let appleScript: AppleScriptPlugin
    let jxaScript: JXAPlugin
    let shellScript: ShellScriptPlugin

    internal init(workspace: NSWorkspace) {
      appleScript = AppleScriptPlugin(workspace: workspace)
      jxaScript = JXAPlugin()
      shellScript = ShellScriptPlugin()
    }
  }

  private let plugins: Plugins

  init(workspace: NSWorkspace = .shared) {
    self.plugins = Plugins(workspace: workspace)
  }

  func run(_ command: ScriptCommand, snapshot: UserSpace.Snapshot, runtimeDictionary: [String: String], checkCancellation: Bool) async throws -> String? {
    var result: String?

    switch (command.kind, command.source) {
    case (.appleScript, .path(let path)):
      result = try await plugins.appleScript.executeScript(at: path, withId: command.id, 
                                                           checkCancellation: checkCancellation)
    case (.appleScript(let variant), .inline(let script)):
      let input = await snapshot.interpolateUserSpaceVariables(script, runtimeDictionary: runtimeDictionary)
      switch variant {
      case .regular:
        result = try await plugins.appleScript.execute(input, withId: command.id,
                                                       checkCancellation: checkCancellation)
      case .jxa:
        result = try await plugins.jxaScript.execute(input, withId: command.id,
                                                     environment: runtimeDictionary,
                                                     checkCancellation: checkCancellation)
      }
    case (.shellScript, .path(let source)):
      let input = await snapshot.interpolateUserSpaceVariables(source, runtimeDictionary: runtimeDictionary)
      result = try await plugins.shellScript.executeScript(at: input, environment: runtimeDictionary,
                                                           checkCancellation: checkCancellation)
    case (.shellScript, .inline(let script)):
      let input = await snapshot.interpolateUserSpaceVariables(script, runtimeDictionary: runtimeDictionary)
      result = try await plugins.shellScript.executeScript(input, environment: runtimeDictionary,
                                                           checkCancellation: checkCancellation)
    }

    return result
  }
}
