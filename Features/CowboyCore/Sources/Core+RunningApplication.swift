import Cocoa
import Foundation

public extension Core {
  final class RunningApplication: Sendable {
    public enum Mode: Sendable {
      case production(NSRunningApplication)
      #if DEBUG
      case testing(BundleIdentifier?)
      #endif
    }

    let mode: Mode

    public var bundleURL: URL? {
      switch mode {
      case .production(let application): application.bundleURL
      #if DEBUG
      case .testing: Testing.mock.bundleURL
      #endif
      }
    }

    public var bundleIdentifier: BundleIdentifier? {
      switch mode {
      case .production(let application):
        application.bundleIdentifier.map(BundleIdentifier.init)
      #if DEBUG
      case .testing(let bundleIdentifier): bundleIdentifier ?? Testing.mock.bundleIdentifier
      #endif
      }
    }

    public var isFinishedLaunching: Bool {
      switch mode {
      case .production(let application): application.isFinishedLaunching
      #if DEBUG
      case .testing: Testing.mock.isFinishedLaunching()
      #endif
      }
    }

    public var isHidden: Bool {
      switch mode {
      case .production(let application): application.isHidden
      #if DEBUG
      case .testing: Testing.mock.isHidden
      #endif
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
      #if DEBUG
      case .testing:
        Testing.mock.activate(options)
      #endif
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
      #if DEBUG
      case (.testing, .testing):
        Testing.mock.activateFrom(fromApplication, options)
      default: false
      #endif
      }
    }

    @discardableResult
    public func hide() -> Bool {
      switch mode {
      case .production(let application): application.hide()
      #if DEBUG
      case .testing: Testing.mock.hide
      #endif
      }
    }

    @discardableResult
    public func terminate() -> Bool {
      switch mode {
      case .production(let application): application.terminate()
      #if DEBUG
      case .testing: Testing.mock.terminate
      #endif
      }
    }

    @discardableResult
    public func unhide() -> Bool {
      switch mode {
      case .production(let application): application.unhide()
      #if DEBUG
      case .testing: Testing.mock.unhide
      #endif
      }
    }

    public static func application(with bundleIdentifier: Core.BundleIdentifier,
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
      #if DEBUG
      case .testing:
        Testing.mock.runningApplications
      #endif
      }
    }
  }
}
