import Foundation

public struct OpenCommand: Codable, Hashable {
  /// If `application` is `nil`, then it should use the
  /// default application that matches the current url
  public let application: Application?
  /// The difference here is that `path` is forced to be a
  /// file-path (file://). There will most certainly be a
  /// difference between the two in terms of UI.
  public let url: URL
}
