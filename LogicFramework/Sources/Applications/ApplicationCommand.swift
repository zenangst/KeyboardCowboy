import Foundation

/// An application command is a container that is used for
/// launching or activing applications.
public struct ApplicationCommand: Codable, Hashable {
  public let id: String
  public var application: Application

  public init(id: String = UUID().uuidString, application: Application) {
    self.id = id
    self.application = application
  }

  enum CodingKeys: String, CodingKey {
    case id
    case application
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.application = try container.decode(Application.self, forKey: .application)
  }
}
