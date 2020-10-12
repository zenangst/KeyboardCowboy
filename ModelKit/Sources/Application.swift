import Foundation

/// `Application` is a data structure used to represent
/// installed applications. It includes bundle identifier,
/// name and url which is enough to determine uniqueness
/// if multiple instance should be installed on a system.
///
/// `Application` is used to launch applications and as a
/// part of `Group` rules.
public struct Application: Codable, Hashable {
  public let bundleIdentifier: String
  public let bundleName: String
  public let path: String

  public init(bundleIdentifier: String,
              bundleName: String,
              path: String) {
    self.bundleIdentifier = bundleIdentifier
    self.bundleName = bundleName
    self.path = path
  }
}

extension Application {
  static func finder() -> Application {
    Application(bundleIdentifier: "com.apple.finder",
                bundleName: "Finder",
                path: "/System/Library/CoreServices/Finder.app")
  }
}
