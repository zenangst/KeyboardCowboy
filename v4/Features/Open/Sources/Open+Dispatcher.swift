import Foundation

public extension Open {
  /// Selects the legacy primary route; execution and error fallback are separate.
  struct Dispatcher: Sendable {
    public enum Route: Sendable, Equatable {
      case host, finder, browser, webApp, generic
    }

    private let hostBundleIdentifier: String
    private let hostBundleURL: URL
    private let parser = URLParser()

    public init(hostBundleIdentifier: String, hostBundleURL: URL) {
      self.hostBundleIdentifier = hostBundleIdentifier
      self.hostBundleURL = hostBundleURL
    }

    public func route(path: String, application: TargetApplication? = nil) -> Route {
      if application?.bundleIdentifier == hostBundleIdentifier {
        return .host
      }
      if !parser.isBrowserEligible(path) {
        let expanded = (path as NSString).expandingTildeInPath
        let resolved = URL(fileURLWithPath: expanded).standardizedFileURL.resolvingSymlinksInPath()
        if resolved.path == hostBundleURL.standardizedFileURL.resolvingSymlinksInPath().path {
          return .host
        }
      }

      if application?.bundleIdentifier.lowercased() == "com.apple.finder" {
        return .finder
      }
      guard parser.isBrowserEligible(path) else { return .generic }

      if let identifier = application?.bundleIdentifier,
         identifier.hasPrefix("com.apple.Safari.WebApp") || identifier.hasPrefix("com.kagi.kagimacOS.WebApp") {
        return .webApp
      }
      return .browser
    }
  }
}
