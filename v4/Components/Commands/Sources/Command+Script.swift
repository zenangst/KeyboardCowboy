public extension Command {
  /// The persisted payload inside the host's `scriptCommand` envelope.
  struct Script: MetaDataProviding {
    public var kind: Kind
    public var source: Source
    public var meta: Metadata

    public init(kind: Kind, source: Source, meta: Metadata = Metadata()) {
      self.kind = kind
      self.source = source
      self.meta = meta
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      if let legacy = try? container.decode(LegacyKind.self, forKey: .kind) {
        kind = switch legacy {
        case .appleScript: .appleScript(variant: .regular)
        case .shellScript: .shellScript
        }
      } else {
        kind = try container.decode(Kind.self, forKey: .kind)
      }
      source = try container.decode(Source.self, forKey: .source)
      meta = try container.decode(Metadata.self, forKey: .meta)
    }

    public func copy() -> Script {
      Script(kind: kind, source: source, meta: meta.copy())
    }

    private enum LegacyKind: String, Decodable {
      case appleScript = "scpt"
      case shellScript = "sh"
    }
  }
}
