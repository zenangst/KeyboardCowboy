import AppKit

public protocol RunningApplication {
  var bundleIdentifier: String? { get }
  var bundleURL: URL? { get }
  var isHidden: Bool { get }
  var isFinishedLaunching: Bool { get }
  var isTerminated: Bool { get }
  var localizedName: String? { get }
  var processIdentifier: pid_t { get }

  static var currentApp: RunningApplication { get }

  @discardableResult
  func activate(options: NSApplication.ActivationOptions) -> Bool
  func terminate() -> Bool
  func hide() -> Bool
  func unhide() -> Bool
}

extension NSRunningApplication: @unchecked @retroactive Sendable, RunningApplication {
  public static var currentApp: RunningApplication {
    NSRunningApplication.current
  }
}
