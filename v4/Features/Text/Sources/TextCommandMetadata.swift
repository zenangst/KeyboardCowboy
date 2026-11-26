import Foundation

public struct TextCommandMetadata: Codable, Sendable, Equatable {
  public enum Notification: String, Codable, Sendable {
    case bezel, commandPanel, capsule
  }

  public var delay: Double?
  public var id: String
  public var name: String
  public var isEnabled: Bool
  public var notification: Notification?
  public var variableName: String?

  public init(delay: Double? = nil, id: String = UUID().uuidString, name: String = "", isEnabled: Bool = true, notification: Notification? = nil, variableName: String? = nil) {
    self.delay = delay
    self.id = id
    self.name = name
    self.isEnabled = isEnabled
    self.notification = notification
    self.variableName = variableName
  }

  private enum CodingKeys: String, CodingKey {
    case delay, id, name, notification, variableName
    case isEnabled = "enabled"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    delay = try container.decodeIfPresent(Double.self, forKey: .delay)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    notification = try? container.decodeIfPresent(Notification.self, forKey: .notification)
    variableName = try container.decodeIfPresent(String.self, forKey: .variableName)
  }
}
