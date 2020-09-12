import Foundation

public protocol ScriptCommandControlling {
  @discardableResult
  func run(_ command: ScriptCommand) throws -> String
}

class ScriptCommandController: ScriptCommandControlling {
  let appleScriptController: AppleScriptControlling
  let shellScriptController: ShellScriptControlling

  init(appleScriptController: AppleScriptControlling,
       shellScriptController: ShellScriptControlling) {
    self.appleScriptController = appleScriptController
    self.shellScriptController = shellScriptController
  }

  func run(_ command: ScriptCommand) throws -> String {
    switch command {
    case .appleScript(let source):
      return try appleScriptController.run(source)
    case .shell(let source):
      return shellScriptController.run(source)
    }
  }
}
