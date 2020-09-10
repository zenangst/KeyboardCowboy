@testable import LogicFramework
import Cocoa

class RunningApplicationMock: RunningApplication {
  var activate: Bool
  var bundleIdentifier: String?

  init(activate: Bool, bundleIdentifier: String) {
    self.activate = activate
    self.bundleIdentifier = bundleIdentifier
  }

  func activate(options: NSApplication.ActivationOptions) -> Bool {
    activate
  }
}
