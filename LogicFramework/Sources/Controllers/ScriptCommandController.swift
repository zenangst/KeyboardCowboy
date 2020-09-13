import Foundation

public protocol ScriptCommandControlling {
  /// Run `ScriptCommand` and switch based on the script type.
  /// The different types are defined inside `ScriptCommand`,
  /// see implementation for more details.
  ///
  /// - Parameter command: The command that should be executed
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
      return try shellScriptController.run(source)
    }
  }
}
