import Foundation

public enum Rule: Codable, Hashable {
  /// Activate when an application is front-most
  case application(Application)
  /// Only active during certain days
  /// TODO: This case needs a value to be passed in
  case days([Day])

  enum CodingKeys: CodingKey {
    case application
    case days
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let value = try? container.decode(Application.self, forKey: .application) {
      self = .application(value)
    } else if let value = try? container.decode([Day].self, forKey: .days) {
      self = .days(value)
    } else {
      throw DecodingError.unableToDecode
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .application(let application):
      try container.encode(application, forKey: .application)
    case .days(let days):
      try container.encode(days, forKey: .days)
    }
  }
}
