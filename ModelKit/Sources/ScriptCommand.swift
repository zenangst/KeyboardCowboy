import Foundation

/// Script command is used to run either Apple- or Shellscripts.
/// Scripts can both point to a file on the file-system or have
/// its underlying script bundled inside the command.
public enum ScriptCommand: Identifiable, Codable, Hashable {
  case appleScript(Source, String)
  case shell(Source, String)

  public enum CodingKeys: CodingKey {
    case appleScript
    case shell
  }

  enum IdentifierCodingKeys: CodingKey {
    case id
  }

  public var id: String {
    switch self {
    case .appleScript(_, let id),
         .shell(_, let id):
      return id
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let idContainer = try decoder.container(keyedBy: IdentifierCodingKeys.self)
    let id = try idContainer.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString

    switch container.allKeys.first {
    case .appleScript:
      let source = try container.decode(Source.self, forKey: .appleScript)
      self = .appleScript(source, id)
    case .shell:
      let source = try container.decode(Source.self, forKey: .shell)
      self = .shell(source, id)
    case .none:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum."
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var idContainer = encoder.container(keyedBy: IdentifierCodingKeys.self)
    switch self {
    case .appleScript(let value, let id):
      try container.encode(value, forKey: .appleScript)
      try idContainer.encode(id, forKey: .id)
    case .shell(let value, let id):
      try container.encode(value, forKey: .shell)
      try idContainer.encode(id, forKey: .id)
    }
  }

  public enum Source: Codable, Equatable, Hashable {
    case path(String)
    case inline(String)

    enum CodingKeys: CodingKey {
      case path
      case inline
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      do {
        let value = try container.decode(String.self, forKey: .path)
        self = .path(value)
      } catch {
        let inline = try container.decode(String.self, forKey: .inline)
        self = .inline(inline)
      }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case .inline(let value):
        try container.encode(value, forKey: .inline)
      case .path(let value):
        try container.encode(value, forKey: .path)
      }
    }
  }
}

public extension ScriptCommand {
  static func empty(_ kind: ScriptCommand.CodingKeys) -> ScriptCommand {
    switch kind {
    case .appleScript:
      return ScriptCommand.appleScript(.path(""), UUID().uuidString)
    case .shell:
      return ScriptCommand.shell(.path(""), UUID().uuidString)
    }
  }
}
