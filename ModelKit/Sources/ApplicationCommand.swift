import Foundation

/// An application command is a container that is used for
/// launching or activing applications.
public struct ApplicationCommand: Identifiable, Codable, Hashable {
  public let id: String
  public var name: String
  public var application: Application

  public init(id: String = UUID().uuidString, name: String = "", application: Application) {
    self.id = id
    self.name = name
    self.application = application
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case application
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    self.application = try container.decode(Application.self, forKey: .application)
  }
}

public extension ApplicationCommand {
  static func empty() -> ApplicationCommand {
    ApplicationCommand(application: Application(bundleIdentifier: "", bundleName: "", path: ""))
  }
}
