import Cocoa

final class ScriptCommandRunner: Sendable {
  private struct Plugins: Sendable {
    let appleScript: AppleScriptPlugin
    let shellScript: ShellScriptPlugin

    internal init(workspace: NSWorkspace) {
      appleScript = AppleScriptPlugin(workspace: workspace)
      shellScript = ShellScriptPlugin()
    }
  }

  private let plugins: Plugins

  init(workspace: NSWorkspace) {
    self.plugins = Plugins(workspace: workspace)
  }

  func run(_ command: ScriptCommand) async throws -> String? {
    var result: String?

    switch (command.kind, command.source) {
    case (.appleScript, .path(let path)):
      result = try await plugins.appleScript.executeScript(at: path, withId: command.id)
    case (.appleScript, .inline(let script)):
      result = try await plugins.appleScript.execute(script, withId: command.id)
    case (.shellScript, .path(let source)):
      result = try plugins.shellScript.executeScript(at: source)
    case (.shellScript, .inline(let script)):
      result = try plugins.shellScript.executeScript(script)
    }

    return result
  }
}
