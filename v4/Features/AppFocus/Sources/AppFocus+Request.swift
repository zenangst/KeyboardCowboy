import ApplicationCatalog
import WindowTilingFeature

public extension AppFocus {
  struct Request: Sendable {
    public let bundleIdentifier: String
    public let createNewWindow: Bool
    public let hideOtherApps: Bool
    public let tiling: WindowTiling.Action?

    public init(
      bundleIdentifier: String, createNewWindow: Bool = true, hideOtherApps: Bool = false,
      tiling: WindowTiling.Action? = nil,
    ) {
      self.bundleIdentifier = bundleIdentifier
      self.createNewWindow = createNewWindow
      self.hideOtherApps = hideOtherApps
      self.tiling = tiling
    }

    var targetsCurrent: Bool { bundleIdentifier == "*.*.current" }

    func resolve(
      catalog: [ApplicationCatalog.Application], current: ApplicationCatalog.Application?,
      previous: ApplicationCatalog.Application?,
    ) -> ApplicationCatalog.Application? {
      switch bundleIdentifier {
      case "*.*.current": current
      case "*.*.previous": previous
      default: catalog.first { $0.bundleIdentifier == bundleIdentifier }
      }
    }
  }
}
