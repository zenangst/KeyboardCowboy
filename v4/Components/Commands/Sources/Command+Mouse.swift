public extension Command {
  /// Persisted mouse-command payload. Associated cases preserve the v3 format.
  struct Mouse: MetaDataProviding {
    public enum Kind: Codable, Hashable, Sendable {
      case click(Target)
      case doubleClick(Target)
      case rightClick(Target)
    }

    public enum Target: Codable, Hashable, Sendable {
      case focused(Anchor)
    }

    public enum Anchor: Codable, Hashable, Sendable {
      case topLeading, top, topTrailing
      case leading, center, trailing
      case bottomLeading, bottom, bottomTrailing
      case custom(x: Int, y: Int)
    }

    public var kind: Kind
    public var meta: Metadata

    public init(kind: Kind = .click(.focused(.center)), meta: Metadata = .init()) {
      self.kind = kind
      self.meta = meta
    }

    public func copy() -> Self {
      Self(kind: kind, meta: meta.copy())
    }
  }
}
