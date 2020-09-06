import Foundation

public struct ScriptCommand: Codable, Hashable {
  public let kind: Kind

  public enum Kind: Codable, Equatable, Hashable {
    case appleScript(Source)
    case shell(Source)

    enum CodingKeys: CodingKey {
      case appleScript
      case shell
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      switch container.allKeys.first {
      case .appleScript:
        let source = try container.decode(Source.self, forKey: .appleScript)
        self = .appleScript(source)
      case .shell:
        let source = try container.decode(Source.self, forKey: .shell)
        self = .shell(source)
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
      switch self {
      case .appleScript(let value):
        try container.encode(value, forKey: .appleScript)
      case .shell(let value):
        try container.encode(value, forKey: .shell)
      }
    }
  }

  public enum Source: Codable, Equatable, Hashable {
    case path(URL)
    case inline(String)

    enum CodingKeys: CodingKey {
      case path
      case inline
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      do {
        let url = try container.decode(URL.self, forKey: .path)
        self = .path(url)
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
