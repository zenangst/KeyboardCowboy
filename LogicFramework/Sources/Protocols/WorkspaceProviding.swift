import Cocoa

public protocol WorkspaceProviding {
  var applications: [RunningApplication] { get }

  func launchApplication(withBundleIdentifier bundleIdentifier: String,
                         options: NSWorkspace.LaunchOptions,
                         additionalEventParamDescriptor descriptor: NSAppleEventDescriptor?,
                         launchIdentifier identifier: AutoreleasingUnsafeMutablePointer<NSNumber?>?) -> Bool
}

extension NSWorkspace: WorkspaceProviding {
  public var applications: [RunningApplication] {
    return runningApplications
  }
}
