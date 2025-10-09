import Cocoa
import Windows

extension WindowModel {
  func convert(_ container: WindowSpace.MapContainer) async -> WindowSpace.Entity? {
    let bundleIdentifier: String
    if let resolvedBundleIdentifier = await container.lookup(ownerPid.rawValue) {
      bundleIdentifier = resolvedBundleIdentifier
    } else if let runningApplication = NSRunningApplication(processIdentifier: pid_t(ownerPid.rawValue)),
              let resolvedBundleIdentifier = runningApplication.bundleIdentifier
    {
      bundleIdentifier = resolvedBundleIdentifier
    } else {
      return nil
    }
    return WindowSpace.Entity(id: id, bundleIdentifier: bundleIdentifier)
  }
}
