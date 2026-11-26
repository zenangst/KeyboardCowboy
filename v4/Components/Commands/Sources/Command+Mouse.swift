public extension Command {
  /// Persisted mouse-command payload. Associated cases preserve the v3 format.
  struct Mouse: MetaDataProviding {
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
