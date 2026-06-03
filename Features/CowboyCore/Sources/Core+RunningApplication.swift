import Cocoa
import Foundation

public extension Core {
  final class RunningApplication: Sendable {
    public enum Mode: Sendable {
      case production(NSRunningApplication)
      case testing
    }

    let mode: Mode

    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var activate: @Sendable (
        _ options: NSApplication.ActivationOptions,
      ) -> Bool
      var activateFrom: @Sendable (
        _ from: RunningApplication,
        _ options: NSApplication.ActivationOptions,
      ) -> Bool
      var bundleIdentifier: BundleIdentifier?
      var hide: Bool
      var isFinishedLaunching: Bool
      var isHidden: Bool
      var runningApplications: [RunningApplication]
      var terminate: Bool

      init(
        activate: @Sendable @escaping (
          _ options: NSApplication.ActivationOptions,
        ) -> Bool = { _ in false },
        activateFrom: @Sendable @escaping (
          _ from: RunningApplication,
          _ options: NSApplication.ActivationOptions,
        ) -> Bool = { _, _ in false },
        bundleIdentifier: BundleIdentifier? = nil,
        hide: Bool = false,
        isFinishedLaunching: Bool = false,
        isHidden: Bool = false,
        runningApplications: [RunningApplication] = [],
        terminate: Bool = false) {
        self.activate = activate
        self.activateFrom = activateFrom
        self.bundleIdentifier = bundleIdentifier
        self.hide = hide
        self.isFinishedLaunching = isFinishedLaunching
        self.isHidden = isHidden
        self.runningApplications = runningApplications
        self.terminate = terminate
      }
    }

    public var bundleIdentifier: BundleIdentifier? {
      switch mode {
      case .production(let application):
        application.bundleIdentifier.map(BundleIdentifier.init)
      case .testing: Testing.mock.bundleIdentifier
      }
    }

    public var isFinishedLaunching: Bool {
      switch mode {
      case .production(let application): application.isFinishedLaunching
      case .testing: Testing.mock.isFinishedLaunching
      }
    }

    public var isHidden: Bool {
      switch mode {
      case .production(let application): application.isHidden
      case .testing: Testing.mock.isHidden
      }
    }

    public init(_ mode: Mode) {
      self.mode = mode
    }

    @discardableResult
    public func activate(options: NSApplication.ActivationOptions = []) -> Bool {
      switch mode {
      case .production(let app):
        app.activate(options: options)
      case .testing:
        Testing.mock.activate(options)
      default: false
      }
    }

    @discardableResult
    public func activate(
      from fromApplication: RunningApplication,
      options: NSApplication.ActivationOptions = [],
    ) -> Bool {
      switch (mode, fromApplication.mode) {
      case (.production(let app), .production(let fromApp)):
        app.activate(from: fromApp, options: options)
      case (.testing, .testing):
        Testing.mock.activateFrom(fromApplication, options)
      default: false
      }
    }

    @discardableResult
    public func hide() -> Bool {
      switch mode {
      case .production(let application): application.hide()
      case .testing: Testing.mock.hide
      }
    }

    public func terminate() -> Bool {
      switch mode {
      case .production(let application): application.terminate()
      case .testing: Testing.mock.terminate
      }
    }

    public static func runningApplication(with bundleIdentifier: Core.BundleIdentifier,
                                          env: Environment) -> RunningApplication? {
      Self.runningApplications(with: bundleIdentifier, env: env).last
    }

    private static func runningApplications(
      with bundleIdentifier: Core.BundleIdentifier,
      env: Environment,
    ) -> [RunningApplication] {
      switch env {
      case .production:
        Cocoa.NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier.value)
          .map { RunningApplication(.production($0)) }
      case .testing:
        Testing.mock.runningApplications
      }
    }
  }
}
