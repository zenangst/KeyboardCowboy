import Cocoa

public protocol RunningApplication {
  var bundleIdentifier: String? { get }

  func activate(options: NSApplication.ActivationOptions) -> Bool
  func terminate() -> Bool
}

extension NSRunningApplication: RunningApplication {}
