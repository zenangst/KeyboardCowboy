@testable import LogicFramework
import Cocoa

class WorkspaceProviderMock: WorkspaceProviding {
  var applications: [RunningApplication]
  var launchApplicationResult: Bool

  init(applications: [RunningApplication] = [], launchApplicationResult: Bool = true) {
    self.applications = applications
    self.launchApplicationResult = launchApplicationResult
  }

  func launchApplication(withBundleIdentifier bundleIdentifier: String, options: NSWorkspace.LaunchOptions,
                         additionalEventParamDescriptor descriptor: NSAppleEventDescriptor?,
                         launchIdentifier identifier: AutoreleasingUnsafeMutablePointer<NSNumber?>?) -> Bool {
    launchApplicationResult
  }
}
