@testable import LogicFramework
import Cocoa

class AppleScriptControllerMock: AppleScriptControlling {
  func run(_ source: ScriptCommand.Source) throws -> String {
    return "true"
  }
}
