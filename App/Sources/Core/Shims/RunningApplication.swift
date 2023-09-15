import Cocoa

public protocol RunningApplication {
  var bundleIdentifier: String? { get }
  var processIdentifier: pid_t { get }

  func activate(options: NSApplication.ActivationOptions) -> Bool
  func terminate() -> Bool
}

extension NSRunningApplication: RunningApplication {}
