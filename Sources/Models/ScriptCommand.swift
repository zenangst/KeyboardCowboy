import Foundation

/// Script command is used to run either Apple- or Shellscripts.
/// Scripts can both point to a file on the file-system or have
/// its underlying script bundled inside the command.
public enum ScriptCommand: Identifiable, Codable, Hashable {
  case appleScript(id: String, name: String?, source: Source)
  case shell(id: String, name: String?, source: Source)

  public enum CodingKeys: CodingKey {
    case appleScript
    case shell
  }

  enum IdentifierCodingKeys: CodingKey {
    case id
    case name
  }

  public var id: String {
    switch self {
    case .appleScript(let id, _, _),
         .shell(let id, _, _):
      return id
    }
  }

  public var hasName: Bool {
    switch self {
    case .appleScript(_, let name, _),
         .shell(_, let name, _):
      return name != nil
    }
  }

  public var name: String {
    switch self {
    case .appleScript(_, let name, _):
      return name ?? "Run Apple Script"
    case .shell(_, let name, _):
      return name ?? "Run Shellscript"
    }
  }

  public var path: String {
    switch self {
    case .appleScript(_, _, let source),
         .shell(_, _, let source):
      switch source {
      case .path(let path):
        return path
      case .inline(_):
        return ""
      }
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let idContainer = try decoder.container(keyedBy: IdentifierCodingKeys.self)
    let id = try idContainer.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    let name = try idContainer.decodeIfPresent(String.self, forKey: .name)

    switch container.allKeys.first {
    case .appleScript:
      let source = try container.decode(Source.self, forKey: .appleScript)
      self = .appleScript(id: id, name: name, source: source)
    case .shell:
      let source = try container.decode(Source.self, forKey: .shell)
      self = .shell(id: id, name: name, source: source)
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
    let commandId: String
    var commandName: String?

    switch self {
    case .appleScript(let id, let name, let source):
      commandId = id
      commandName = name
      try container.encode(source, forKey: .appleScript)
    case .shell(let id, let name, let source):
      commandId = id
      commandName = name
      try container.encode(source, forKey: .shell)
    }

    try idContainer.encode(commandId, forKey: .id)
    if commandName != nil {
      try idContainer.encode(commandName, forKey: .name)
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
  static func empty(_ kind: ScriptCommand.CodingKeys, id: String = UUID().uuidString) -> ScriptCommand {
    switch kind {
    case .appleScript:
      return ScriptCommand.appleScript(id: id, name: nil, source: .path(""))
    case .shell:
      return ScriptCommand.shell(id: id, name: nil, source: .path(""))
    }
  }
}
