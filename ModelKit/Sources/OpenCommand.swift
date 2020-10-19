import Foundation

/// This command is used to open folders, files, web
/// or custom urls.
public struct OpenCommand: Identifiable, Codable, Hashable {
  public let id: String
  /// If `application` is `nil`, then it should use the
  /// default application that matches the current url
  public let application: Application?
  /// The difference here is that `path` is forced to be a
  /// file-path (file://). There will most certainly be a
  /// difference between the two in terms of UI.
  public let path: String
  public var name: String

  public var isUrl: Bool {
    if let url = URL(string: path) {
      if url.host == nil || url.isFileURL {
        return false
      } else {
        return true
      }
    } else {
      return false
    }
  }

  public init(id: String = UUID().uuidString,
              name: String = "",
              application: Application? = nil, path: String) {
    self.id = id
    self.name = name
    self.application = application
    self.path = path
  }

  enum CodingKeys: String, CodingKey {
    case id
    case application
    case name
    case path
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    self.application = try container.decodeIfPresent(Application.self, forKey: .application)
    self.path = try container.decode(String.self, forKey: .path)
  }
}

public extension OpenCommand {
  static func empty() -> OpenCommand {
    OpenCommand(path: "")
  }
}
