@testable import LogicFramework
import Cocoa

class WorkspaceProviderMock: WorkspaceProviding {
  typealias OpenHandler = WorkspaceCompletion?
  typealias OpenResult = (runningApplication: RunningApplication?, error: OpenCommandControllingError?)

  var frontApplication: RunningApplication?
  var applications: [RunningApplication]
  var launchApplicationResult: Bool
  var openFileResult: OpenResult?

  init(applications: [RunningApplication] = [],
       launchApplicationResult: Bool = true,
       openFileResult: OpenResult? = nil) {
    self.applications = applications
    self.launchApplicationResult = launchApplicationResult
    self.openFileResult = openFileResult
  }

  func launchApplication(withBundleIdentifier bundleIdentifier: String, options: NSWorkspace.LaunchOptions,
                         additionalEventParamDescriptor descriptor: NSAppleEventDescriptor?,
                         launchIdentifier identifier: AutoreleasingUnsafeMutablePointer<NSNumber?>?) -> Bool {
    launchApplicationResult
  }

  func open(_ url: URL, config: NSWorkspace.OpenConfiguration,
            completionHandler: ((RunningApplication?, Error?) -> Void)?) {
    let ctx = openFileResult
    completionHandler?(ctx?.runningApplication, ctx?.error)
  }

  func open(_ urls: [URL], withApplicationAt applicationURL: URL,
            config: NSWorkspace.OpenConfiguration,
            completionHandler: ((RunningApplication?, Error?) -> Void)?) {
    let ctx = openFileResult
    completionHandler?(ctx?.runningApplication, ctx?.error)
  }

  func reveal(_ path: String) {}
}
