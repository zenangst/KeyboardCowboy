import Foundation

struct OpenCommand {
  /// If `bundleIdentifier` is `nil`, then it should use the
  /// default application that matches the current url
  let bundleIdentifier: String?
  /// The difference here is that `path` is forced to be a
  /// file-path (file://). There will most certainly be a
  /// difference between the two in terms of UI.
  let kind: Kind

  enum Kind {
    case path(URL)
    case url(URL)
  }
}
