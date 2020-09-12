@testable import LogicFramework
import Cocoa

class ShellScriptControllerMock: ShellScriptControlling {
  func run(_ source: ScriptCommand.Source) -> String {
    return "true"
  }
}
