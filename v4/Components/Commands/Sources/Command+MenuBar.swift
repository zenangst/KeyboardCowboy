import Apps

public extension Command {
  /// Persisted menu-bar payload. An absent application means the frontmost app.
  struct MenuBar: MetaDataProviding {
    public enum Token: Codable, Hashable, Sendable {
      case menuItem(name: String)
      case menuItems(name: String, fallbackName: String)
    }

    public let tokens: [Token]
    public var application: Apps.Application?
    public var meta: Metadata

    public init(application: Apps.Application? = nil, tokens: [Token], meta: Metadata = .init()) {
      self.application = application
      self.tokens = tokens
      self.meta = meta
    }

    public func copy() -> Self {
      Self(application: application, tokens: tokens, meta: meta.copy())
    }
  }
}
