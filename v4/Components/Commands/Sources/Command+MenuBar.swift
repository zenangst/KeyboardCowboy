import ApplicationCatalog

public extension Command {
  /// Persisted menu-bar payload. An absent application means the frontmost app.
  struct MenuBar: MetaDataProviding {
    public let tokens: [Token]
    public var application: ApplicationCatalog.Application?
    public var meta: Metadata

    public init(application: ApplicationCatalog.Application? = nil, tokens: [Token], meta: Metadata = .init()) {
      self.application = application
      self.tokens = tokens
      self.meta = meta
    }

    public func copy() -> Self {
      Self(application: application, tokens: tokens, meta: meta.copy())
    }
  }
}
