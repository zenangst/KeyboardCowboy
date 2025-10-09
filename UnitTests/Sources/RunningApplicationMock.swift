import Cocoa
import Foundation
@testable import Keyboard_Cowboy

class RunningApplicationMock: @preconcurrency RunningApplication {
  var isFinishedLaunching: Bool = true
  var bundleIdentifier: String?
  var bundleURL: URL?
  var isHidden: Bool
  var isTerminated: Bool
  var localizedName: String?
  var processIdentifier: pid_t

  @MainActor static let currentApp = NSRunningApplication.currentApp

  init(bundleIdentifier: String? = nil, bundleURL: URL? = nil, isHidden: Bool = false,
       isTerminated: Bool = false, localizedName: String? = nil, processIdentifier: pid_t)
  {
    self.bundleIdentifier = bundleIdentifier
    self.bundleURL = bundleURL
    self.isHidden = isHidden
    self.isTerminated = isTerminated
    self.localizedName = localizedName
    self.processIdentifier = processIdentifier
  }

  func activate(options _: NSApplication.ActivationOptions) -> Bool { false }
  func terminate() -> Bool { false }
  func hide() -> Bool { false }
  func unhide() -> Bool { false }
}
