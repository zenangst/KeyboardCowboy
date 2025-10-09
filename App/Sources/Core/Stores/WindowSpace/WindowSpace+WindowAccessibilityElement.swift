import AXEssibility
import Cocoa

extension WindowAccessibilityElement {
  func convert(with container: WindowSpace.MapContainer) async -> WindowSpace.Entity? {
    guard let pid32 = app?.pid else {
      return nil
    }

    let pid = Int(pid32)
    let bundleIdentifier: String
    if let resolvedBundleIdentifier = await container.lookup(pid) {
      bundleIdentifier = resolvedBundleIdentifier
    } else if let runningApplication = NSRunningApplication(processIdentifier: pid_t(pid)),
              let resolvedBundleIdentifier = runningApplication.bundleIdentifier
    {
      bundleIdentifier = resolvedBundleIdentifier
    } else {
      return nil
    }

    let kind: WindowSpace.Entity.Kind = switch subrole {
    case "AXStandardWindow": .standard
    case "AXDialog": .dialog
    default: .unknown
    }

    let properties: WindowSpace.Entity.Properties = .init(title: title, identifier: identifier)

    return WindowSpace.Entity(id: Int(id),
                              bundleIdentifier: bundleIdentifier,
                              kind: kind,
                              properties: properties)
  }
}
