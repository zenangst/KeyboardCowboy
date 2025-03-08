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

  func run(_ command: ScriptCommand, environment: [String: String], checkCancellation: Bool) async throws -> String? {
    var result: String?

    switch (command.kind, command.source) {
    case (.appleScript, .path(let path)):
      result = try await plugins.appleScript.executeScript(at: path, withId: command.id, 
                                                           checkCancellation: checkCancellation)
    case (.appleScript(let variant), .inline(let script)):
      switch variant {
      case .regular:
        result = try await plugins.appleScript.execute(script, withId: command.id,
                                                       checkCancellation: checkCancellation)
      case .jxa:
        result = try await plugins.jxaScript.execute(script, withId: command.id, checkCancellation: checkCancellation)
      }
    case (.shellScript, .path(let source)):
      result = try await plugins.shellScript.executeScript(at: source, environment: environment,
                                                           checkCancellation: checkCancellation)
    case (.shellScript, .inline(let script)):
      result = try await plugins.shellScript.executeScript(script, environment: environment,
                                                           checkCancellation: checkCancellation)
    }

    return result
  }
}
