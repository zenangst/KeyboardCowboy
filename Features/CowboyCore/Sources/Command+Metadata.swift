import Foundation

public extension Command {
  struct Metadata: Identifiable, Codable, Hashable, Sendable {
    public var id: String

    var delay: Double?
    var name: String
    var isEnabled: Bool
    var notification: Notification?
    var variableName: String?

    enum CodingKeys: String, CodingKey {
      case delay
      case id
      case name
      case isEnabled = "enabled"
      case notification
      case variableName
    }

    init(delay: Double? = nil,
         id: String = UUID().uuidString,
         name: String = "",
         isEnabled: Bool = true,
         notification: Notification? = nil,
         variableName: String? = nil) {
      self.delay = delay
      self.id = id
      self.name = name
      self.isEnabled = isEnabled
      self.notification = notification
      self.variableName = variableName
    }

    func copy() -> Metadata {
      Metadata(delay: delay,
               id: UUID().uuidString,
               name: name,
               isEnabled: isEnabled,
               notification: notification,
               variableName: variableName)
    }

    public init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<Metadata.CodingKeys> = try decoder.container(keyedBy: Metadata.CodingKeys.self)
      delay = try container.decodeIfPresent(Double.self, forKey: Metadata.CodingKeys.delay)
      id = try container.decode(String.self, forKey: Metadata.CodingKeys.id)
      name = try container.decode(String.self, forKey: Metadata.CodingKeys.name)
      isEnabled = try container.decode(Bool.self, forKey: Metadata.CodingKeys.isEnabled)
      notification = try? container.decodeIfPresent(Command.Notification.self, forKey: Metadata.CodingKeys.notification)
      variableName = try container.decodeIfPresent(String.self, forKey: Metadata.CodingKeys.variableName)
    }
  }
}
