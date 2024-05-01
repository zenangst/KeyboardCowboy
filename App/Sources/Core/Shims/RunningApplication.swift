import Cocoa

public protocol RunningApplication {
  var bundleIdentifier: String? { get }
  var processIdentifier: pid_t { get }
  var isHidden: Bool { get }

  func activate(options: NSApplication.ActivationOptions) -> Bool
  func terminate() -> Bool
  func hide() -> Bool
  func unhide() -> Bool
}

extension NSRunningApplication: RunningApplication {}
