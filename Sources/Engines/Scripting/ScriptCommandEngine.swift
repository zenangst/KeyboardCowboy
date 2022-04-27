import Foundation

final class ScriptCommandEngine {
  private struct Plugins {
    let appleScript = AppleScriptPlugin()
    let shellScript = ShellScriptPlugin()
  }

  private let plugins: Plugins

  init() {
    self.plugins = Plugins()
  }

  func run(_ command: ScriptCommand) async throws {
    switch command {
    case .appleScript(let id, _, _, let source):
      switch source {
      case .path(let path):
        try plugins.appleScript.executeScript(at: path, withId: id)
      case .inline(let script):
        try plugins.appleScript.execute(script, withId: id)
      }
    case .shell(let id, let isEnabled, let name, let source):
      switch source {
      case .path(let string):
        break
      case .inline(let string):
        break
      }
    }
  }
}
