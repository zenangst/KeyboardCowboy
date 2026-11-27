import Commands

public extension Workspaces {
  /// The v3 `bundled` envelope for saved workspace and App Focus commands.
  /// This is a persistence adapter, not a dispatcher for bundled commands.
  struct SavedCommand: Codable, Hashable, Sendable {
    public let kind: Kind
    public let meta: Command.Metadata

    public init(kind: Kind, meta: Command.Metadata) {
      self.kind = kind
      self.meta = meta
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: EnvelopeKey.self)
      let bundled = try container.nestedContainer(keyedBy: PayloadKey.self, forKey: .bundled)
      kind = try bundled.decode(Kind.self, forKey: .kind)
      meta = try bundled.decode(Command.Metadata.self, forKey: .meta)
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: EnvelopeKey.self)
      var bundled = container.nestedContainer(keyedBy: PayloadKey.self, forKey: .bundled)
      try bundled.encode(kind, forKey: .kind)
      try bundled.encode(meta, forKey: .meta)
    }

    private enum EnvelopeKey: CodingKey { case bundled }
    private enum PayloadKey: CodingKey { case kind, meta }
  }
}
