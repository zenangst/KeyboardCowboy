import Cocoa

final class ScriptEngine {
  private struct Plugins {
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
    switch command {
    case .appleScript(let id, _, _, let source):
      switch source {
      case .path(let path):
        result = try plugins.appleScript.executeScript(at: path, withId: id)
      case .inline(let script):
        result = try plugins.appleScript.execute(script, withId: id)
      }
    case .shell(_, _, _, let source):
      switch source {
      case .path(let path):
        result = try plugins.shellScript.executeScript(at: path)
      case .inline(let source):
        result = try plugins.shellScript.executeScript(source)
      }
    }

    return result
  }
}
