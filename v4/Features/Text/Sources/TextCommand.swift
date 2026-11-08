import Foundation

/// The persisted text-command envelope. Input is not interpolated during decoding.
public struct TextCommandEnvelope: Codable, Sendable, Equatable {
  public var textCommand: TextCommand

  public init(textCommand: TextCommand) {
    self.textCommand = textCommand
  }
}

public struct TextCommand: Codable, Sendable, Equatable {
  public enum Kind: Codable, Sendable, Equatable {
    case insertText(TextInsertCommand)
  }

  public var kind: Kind

  public init(kind: Kind) {
    self.kind = kind
  }
}

public struct TextCommandMetadata: Codable, Sendable, Equatable {
  public enum Notification: String, Codable, Sendable {
    case bezel, commandPanel, capsule
  }

  public var delay: Double?
  public var id: String
  public var name: String
  public var isEnabled: Bool
  public var notification: Notification?
  public var variableName: String?

  public init(delay: Double? = nil, id: String = UUID().uuidString, name: String = "", isEnabled: Bool = true, notification: Notification? = nil, variableName: String? = nil) {
    self.delay = delay
    self.id = id
    self.name = name
    self.isEnabled = isEnabled
    self.notification = notification
    self.variableName = variableName
  }

  private enum CodingKeys: String, CodingKey {
    case delay, id, name, notification, variableName
    case isEnabled = "enabled"
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    delay = try container.decodeIfPresent(Double.self, forKey: .delay)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    notification = try? container.decodeIfPresent(Notification.self, forKey: .notification)
    variableName = try container.decodeIfPresent(String.self, forKey: .variableName)
  }
}

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
