public struct TextInsertCommand: Codable, Sendable, Equatable {
  public var input: String
  public var mode: TextExecution.Mode
  public var meta: TextCommandMetadata
  public var actions: Set<TextExecution.Action>

  public init(input: String, mode: TextExecution.Mode = .instant, meta: TextCommandMetadata = .init(), actions: Set<TextExecution.Action> = []) {
    self.input = input
    self.mode = mode
    self.meta = meta
    self.actions = actions
  }

  private enum CodingKeys: CodingKey { case input, mode, meta, actions }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    input = try container.decode(String.self, forKey: .input)
    mode = try container.decodeIfPresent(TextExecution.Mode.self, forKey: .mode) ?? .instant
    meta = try container.decode(TextCommandMetadata.self, forKey: .meta)
    actions = try container.decodeIfPresent(Set<TextExecution.Action>.self, forKey: .actions) ?? []
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(input, forKey: .input)
    try container.encode(mode, forKey: .mode)
    try container.encode(meta, forKey: .meta)
    try container.encode(actions.sorted { $0.rawValue < $1.rawValue }, forKey: .actions)
  }

  /// The host resolves `input` once using its snapshot and runtime values.
  public func execution(resolvedInput: String) -> TextExecution {
    TextExecution(input: resolvedInput, mode: mode, actions: actions)
  }
}
