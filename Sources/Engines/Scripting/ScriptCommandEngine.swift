import Foundation

final class ScriptCommandEngine {
  private struct Plugins {
    let appleScript = AppleScriptPlugin()
    let shellScript = ShellScriptPlugin()
  }

  private let plugins = Plugins()


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
