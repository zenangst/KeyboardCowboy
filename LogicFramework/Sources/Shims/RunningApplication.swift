import Cocoa

public protocol RunningApplication {
  var bundleIdentifier: String? { get }

  func activate(options: NSApplication.ActivationOptions) -> Bool
}

extension NSRunningApplication: RunningApplication {}
