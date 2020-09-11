import Cocoa

public typealias WorkspaceCompletion = ((RunningApplication?, Error?) -> Void)
public protocol WorkspaceProviding {
  var applications: [RunningApplication] { get }

  func launchApplication(withBundleIdentifier bundleIdentifier: String,
                         options: NSWorkspace.LaunchOptions,
                         additionalEventParamDescriptor descriptor: NSAppleEventDescriptor?,
                         launchIdentifier identifier: AutoreleasingUnsafeMutablePointer<NSNumber?>?) -> Bool

  func open(_ url: URL,
            config: NSWorkspace.OpenConfiguration,
            completionHandler: ((RunningApplication?, Error?) -> Void)?)

  func open(_ urls: [URL], withApplicationAt applicationURL: URL,
            config: NSWorkspace.OpenConfiguration,
            completionHandler: ((RunningApplication?, Error?) -> Void)?)
}

extension NSWorkspace: WorkspaceProviding {
  public var applications: [RunningApplication] {
    return runningApplications
  }

  public func open(_ url: URL,
                   config: NSWorkspace.OpenConfiguration,
                   completionHandler: WorkspaceCompletion?) {
    let configuration: NSWorkspace.OpenConfiguration = .init()
    open(url, configuration: configuration) { (runningApplication, error) in
      completionHandler?(runningApplication, error)
    }
  }

  public func open(_ urls: [URL], withApplicationAt applicationUrl: URL,
                   config: NSWorkspace.OpenConfiguration,
                   completionHandler: WorkspaceCompletion?) {
    open(urls, withApplicationAt: applicationUrl, configuration: config) { (runningApplication, error) in
      completionHandler?(runningApplication, error)
    }
  }
}
