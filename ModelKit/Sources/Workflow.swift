import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
public struct Workflow: Identifiable, Codable, Hashable {
  public struct MetaData: Codable, Hashable {
    public var runWhenApplicationsAreLaunched: [String] = []
    public var runWhenApplicationsAreClosed: [String] = []

    var isEncodable: Bool {
      !runWhenApplicationsAreLaunched.isEmpty ||
        !runWhenApplicationsAreClosed.isEmpty
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      if !runWhenApplicationsAreLaunched.isEmpty {
        try container.encode(runWhenApplicationsAreLaunched, forKey: .runWhenApplicationsAreLaunched)
      }
      if !runWhenApplicationsAreClosed.isEmpty {
        try container.encode(runWhenApplicationsAreClosed, forKey: .runWhenApplicationsAreClosed)
      }
    }
  }

  public enum Trigger: Hashable, Codable {
    case keyboardShortcuts([KeyboardShortcut])

    public enum CodingKeys: String, CodingKey {
      case keyboardShortcuts
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      switch container.allKeys.first {
      case .keyboardShortcuts:
        let keyboardShortcuts = try container.decode([KeyboardShortcut].self, forKey: .keyboardShortcuts)
        self = .keyboardShortcuts(keyboardShortcuts)
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
      case .keyboardShortcuts(let keyboardShortcuts):
        try container.encode(keyboardShortcuts, forKey: .keyboardShortcuts)
      }
    }
  }

  public let id: String
  public var commands: [Command]
  public var trigger: Trigger?
  @available(*, deprecated, message: "Use .trigger instead.")
  public var keyboardShortcuts: [KeyboardShortcut] = []
  public var name: String
  public var metadata: MetaData = MetaData()

  public var isRebinding: Bool {
    if commands.count == 1, case .keyboard = commands.first { return true }
    return false
  }

  public init(id: String = UUID().uuidString, name: String,
              trigger: Trigger?,
              commands: [Command] = []) {
    self.id = id
    self.commands = commands
    self.trigger = trigger
    self.name = name
  }

  enum CodingKeys: String, CodingKey {
    case commands
    case id
    case trigger
    case keyboardShortcuts
    case metadata
    case name
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decode(String.self, forKey: .name)
    self.commands = try container.decode([Command].self, forKey: .commands)

    // Migrate keyboard shortcuts to trigger property
    if let keyboardShortcuts = try? container.decode([KeyboardShortcut].self, forKey: .keyboardShortcuts) {
      self.trigger = .keyboardShortcuts(keyboardShortcuts)
    } else {
      self.trigger = try container.decodeIfPresent(Trigger.self, forKey: .trigger)
    }
    self.metadata = try container.decodeIfPresent(MetaData.self, forKey: .metadata) ?? MetaData()

  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    if !commands.isEmpty {
      try container.encode(commands, forKey: .commands)
    }

    // Trigger takes precedence over keyboard shortcuts.
    if let trigger = trigger {
      try container.encode(trigger, forKey: .trigger)
    }

    if metadata.isEncodable {
      try container.encode(metadata, forKey: .metadata)
    }
  }
}

extension Workflow {
  static public func empty(id: String = UUID().uuidString) -> Workflow {
    Workflow(
      id: id,
      name: "Untitled workflow",
      trigger: nil,
      commands: []
    )
  }
}
