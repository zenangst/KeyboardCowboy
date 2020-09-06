import Foundation

public enum Command: Codable, Hashable {
  case application(ApplicationCommand)
  case keyboard(KeyboardCommand)
  case open(OpenCommand)
  case script(ScriptCommand)

  enum CodingKeys: String, CodingKey {
    case application = "applicationCommand"
    case keyboard = "keyboardCommand"
    case open = "openCommand"
    case script = "scriptCommand"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let command = try? container.decode(ApplicationCommand.self, forKey: .application) {
      self = .application(command)
    } else if let command = try? container.decode(KeyboardCommand.self, forKey: .keyboard) {
      self = .keyboard(command)
    } else if let command = try? container.decode(OpenCommand.self, forKey: .open) {
      self = .open(command)
    } else if let command = try? container.decode(ScriptCommand.self, forKey: .script) {
      self = .script(command)
    } else {
      throw DecodingError.unableToDecode
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .application(let command):
      try container.encode(command, forKey: .application)
    case .keyboard(let command):
      try container.encode(command, forKey: .keyboard)
    case .open(let command):
      try container.encode(command, forKey: .open)
    case .script(let command):
      try container.encode(command, forKey: .script)
    }
  }
}
