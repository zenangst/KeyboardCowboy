import Foundation

/// `Application` is a data structure used to represent
/// installed applications. It includes bundle identifier,
/// name and url which is enough to determine uniqueness
/// if multiple instance should be installed on a system.
///
/// `Application` is used to launch applications and as a
/// part of `Group` rules.
public struct Application: Identifiable, Codable, Hashable {
  public let id: String
  public let bundleIdentifier: String
  public let bundleName: String
  public let path: String

  public init(id: String = UUID().uuidString,
              bundleIdentifier: String,
              bundleName: String,
              path: String) {
    self.id = id
    self.bundleIdentifier = bundleIdentifier
    self.bundleName = bundleName
    self.path = path
  }

  enum CodingKeys: String, CodingKey {
    case id
    case bundleIdentifier
    case bundleName
    case path
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
    self.bundleName = try container.decode(String.self, forKey: .bundleName)
    self.path = try container.decode(String.self, forKey: .path)
  }
}

public extension Application {
  static func empty(id: String = UUID().uuidString) -> Application {
    Application(id: id, bundleIdentifier: "", bundleName: "", path: "")
  }

  static func messages(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.apple.MobileSMS",
      bundleName: "Messages",
      path: "/System/Applications/Messages.app")
  }

  static func finder(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.apple.finder",
      bundleName: "Finder", path: "/System/Library/CoreServices/Finder.app")
  }

  static func photoshop(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.adobe.Photoshop",
      bundleName: "Photoshop",
      path: "/Applications/Adobe Photoshop 2020/Adobe Photoshop 2020.app")
  }

  static func sketch(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.bohemiancoding.sketch3",
      bundleName: "Sketch",
      path: "/Applications/Sketch.app")
  }

  static func safari(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.apple.Safari",
      bundleName: "Safari",
      path: "/Applications/Safari.app")
  }
  
  static func xcode(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.apple.dt.Xcode",
      bundleName: "Sketch",
      path: "/Applications/Xcode.app")
  }

  static func music(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.apple.music",
      bundleName: "Music",
      path: "/System/Applications/Music.app")
  }

  static func calendar(id: String = UUID().uuidString) -> Application {
    Application(
      id: id,
      bundleIdentifier: "com.apple.calendar",
      bundleName: "Calendar",
      path: "/System/Applications/Calendar.app")
  }

}
