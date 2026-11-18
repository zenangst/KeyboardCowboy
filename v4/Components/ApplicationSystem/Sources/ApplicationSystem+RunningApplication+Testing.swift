#if DEBUG
import Cocoa
import Foundation

public extension ApplicationSystem.RunningApplication {
  enum Testing {
    @TaskLocal public static var mock: Mock = Mock()
  }

  struct Mock: Sendable {
    var activate: @Sendable (
      _ options: NSApplication.ActivationOptions,
    ) -> Bool
    var activateFrom: @Sendable (
      _ from: ApplicationSystem.RunningApplication,
      _ options: NSApplication.ActivationOptions,
    ) -> Bool
    var bundleIdentifier: ApplicationSystem.BundleIdentifier?
    var bundleURL: URL?
    var hide: Bool
    var isFinishedLaunching: @Sendable () -> Bool
    var isHidden: Bool
    var isTerminated: Bool
    var runningApplications: [ApplicationSystem.RunningApplication]
    var runningApplicationsLookup: (@Sendable (ApplicationSystem.BundleIdentifier) -> [ApplicationSystem.RunningApplication])?
    var terminate: Bool
    var unhide: Bool
    var onHide: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)?
    var onTerminate: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)?
    var onUnhide: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)?
    var onActivate: (@Sendable (ApplicationSystem.RunningApplication, NSApplication.ActivationOptions) -> Bool)?
    var onIsTerminated: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)?

    init(
      activate: @Sendable @escaping (
        _ options: NSApplication.ActivationOptions,
      ) -> Bool = { _ in false },
      activateFrom: @Sendable @escaping (
        _ from: ApplicationSystem.RunningApplication,
        _ options: NSApplication.ActivationOptions,
      ) -> Bool = { _, _ in false },
      bundleIdentifier: ApplicationSystem.BundleIdentifier? = nil,
      bundleURL: URL? = nil,
      hide: Bool = false,
      isFinishedLaunching: @escaping @Sendable () -> Bool = { false },
      isHidden: Bool = false,
      isTerminated: Bool = false,
      runningApplications: [ApplicationSystem.RunningApplication] = [],
      runningApplicationsLookup: (@Sendable (ApplicationSystem.BundleIdentifier) -> [ApplicationSystem.RunningApplication])? = nil,
      unhide: Bool = false,
      terminate: Bool = false,
      onHide: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)? = nil,
      onTerminate: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)? = nil,
      onUnhide: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)? = nil,
      onActivate: (@Sendable (ApplicationSystem.RunningApplication, NSApplication.ActivationOptions) -> Bool)? = nil,
      onIsTerminated: (@Sendable (ApplicationSystem.RunningApplication) -> Bool)? = nil) {
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
      self.onActivate = onActivate
      self.onIsTerminated = onIsTerminated
    }
  }
}
#endif
