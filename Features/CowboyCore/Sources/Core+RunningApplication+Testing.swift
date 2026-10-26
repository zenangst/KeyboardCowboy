#if DEBUG
import Cocoa
import Foundation

extension Core.RunningApplication {
  public enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  public struct Mock: Sendable {
    var activate: @Sendable (
      _ options: NSApplication.ActivationOptions,
    ) -> Bool
    var activateFrom: @Sendable (
      _ from: Core.RunningApplication,
      _ options: NSApplication.ActivationOptions,
    ) -> Bool
    var bundleIdentifier: Core.BundleIdentifier?
    var bundleURL: URL?
    var hide: Bool
    var isFinishedLaunching: @Sendable () -> Bool
    var isHidden: Bool
    var runningApplications: [Core.RunningApplication]
    var terminate: Bool
    var unhide: Bool

    init(
      activate: @Sendable @escaping (
        _ options: NSApplication.ActivationOptions,
      ) -> Bool = { _ in false },
      activateFrom: @Sendable @escaping (
        _ from: Core.RunningApplication,
        _ options: NSApplication.ActivationOptions,
      ) -> Bool = { _, _ in false },
      bundleIdentifier: Core.BundleIdentifier? = nil,
      bundleURL: URL? = nil,
      hide: Bool = false,
      isFinishedLaunching: @escaping @Sendable () -> Bool = { false },
      isHidden: Bool = false,
      runningApplications: [Core.RunningApplication] = [],
      unhide: Bool = false,
      terminate: Bool = false) {
      self.activate = activate
      self.activateFrom = activateFrom
      self.bundleIdentifier = bundleIdentifier
      self.bundleURL = bundleURL
      self.hide = hide
      self.isFinishedLaunching = isFinishedLaunching
      self.isHidden = isHidden
      self.runningApplications = runningApplications
      self.terminate = terminate
      self.unhide = unhide
    }
  }
}
#endif
