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
    var isTerminated: Bool
    var runningApplications: [Core.RunningApplication]
    var runningApplicationsLookup: (@Sendable (Core.BundleIdentifier) -> [Core.RunningApplication])?
    var terminate: Bool
    var unhide: Bool
    var onHide: (@Sendable (Core.RunningApplication) -> Bool)?
    var onTerminate: (@Sendable (Core.RunningApplication) -> Bool)?
    var onUnhide: (@Sendable (Core.RunningApplication) -> Bool)?

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
      isTerminated: Bool = false,
      runningApplications: [Core.RunningApplication] = [],
      runningApplicationsLookup: (@Sendable (Core.BundleIdentifier) -> [Core.RunningApplication])? = nil,
      unhide: Bool = false,
      terminate: Bool = false,
      onHide: (@Sendable (Core.RunningApplication) -> Bool)? = nil,
      onTerminate: (@Sendable (Core.RunningApplication) -> Bool)? = nil,
      onUnhide: (@Sendable (Core.RunningApplication) -> Bool)? = nil) {
      self.activate = activate
      self.activateFrom = activateFrom
      self.bundleIdentifier = bundleIdentifier
      self.bundleURL = bundleURL
      self.hide = hide
      self.isFinishedLaunching = isFinishedLaunching
      self.isHidden = isHidden
      self.isTerminated = isTerminated
      self.runningApplications = runningApplications
      self.runningApplicationsLookup = runningApplicationsLookup
      self.terminate = terminate
      self.unhide = unhide
      self.onHide = onHide
      self.onTerminate = onTerminate
      self.onUnhide = onUnhide
    }
  }
}
#endif
