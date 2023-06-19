import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
struct Workflow: Identifiable, Equatable, Codable, Hashable, Sendable {
  enum Trigger: Hashable, Equatable, Codable, Sendable {
    case application([ApplicationTrigger])
    case keyboardShortcuts(KeyboardShortcutTrigger)

    enum CodingKeys: String, CodingKey {
      case application
      case keyboardShortcuts
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      switch container.allKeys.first {
      case .application:
        let applicationTrigger = try container.decode([ApplicationTrigger].self, forKey: .application)
        self = .application(applicationTrigger)
      case .keyboardShortcuts:
        do {
          let keyboardShortcutTrigger = try container.decode(KeyboardShortcutTrigger.self, forKey: .keyboardShortcuts)
          self = .keyboardShortcuts(keyboardShortcutTrigger)
        } catch {
          Migration.shouldSave = true
          let keyboardShortcuts = try container.decode([KeyShortcut].self, forKey: .keyboardShortcuts)
          self = .keyboardShortcuts(.init(shortcuts: keyboardShortcuts))
        }
      case .none:
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "Unabled to decode enum."
          )
        )
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case .application(let trigger):
        try container.encode(trigger, forKey: .application)
      case .keyboardShortcuts(let keyboardShortcuts):
        try container.encode(keyboardShortcuts, forKey: .keyboardShortcuts)
      }
    }

    static func ==(lhs: Trigger, rhs: Trigger) -> Bool {
      switch (lhs, rhs) {
      case (.application(let lhsTriggers), .application(let rhsTriggers)):
        return lhsTriggers == rhsTriggers
      case (.keyboardShortcuts(let lhsShortcuts), .keyboardShortcuts(let rhsShortcuts)):
        return lhsShortcuts == rhsShortcuts
      default:
        return false
      }
    }
  }

  enum Execution: String, Hashable, Codable {
    case concurrent
    case serial
  }

  private(set) var id: String
  var commands: [Command]
  var trigger: Trigger?
  var isEnabled: Bool = true
  var name: String
  var execution: Execution

  var isRebinding: Bool {
    if commands.count == 1, case .keyboard = commands.first { return true }
    return false
  }

  init(id: String = UUID().uuidString, name: String,
       trigger: Trigger? = nil,
       execution: Execution = .concurrent,
       isEnabled: Bool = true,
       commands: [Command] = []
       ) {
    self.id = id
    self.commands = commands
    self.trigger = trigger
    self.name = name
    self.isEnabled = isEnabled
    self.execution = execution
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString
    clone.name += " copy"
    return clone
  }

  enum CodingKeys: String, CodingKey {
    case commands
    case id
    case trigger
    case keyboardShortcuts
    case metadata
    case name
    case isEnabled = "enabled"
    case execution
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decode(String.self, forKey: .name)
    self.commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
    self.execution = try container.decodeIfPresent(Execution.self, forKey: .execution) ?? .concurrent
    self.trigger = try container.decodeIfPresent(Trigger.self, forKey: .trigger)
    self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(execution, forKey: .execution)
    if !commands.isEmpty {
      try container.encode(commands, forKey: .commands)
    }

    // Trigger takes precedence over keyboard shortcuts.
    if let trigger = trigger {
      try container.encode(trigger, forKey: .trigger)
    }

    if isEnabled == false {
      try container.encode(isEnabled, forKey: .isEnabled)
    }
  }

  mutating func updateOrAddCommand(_ command: Command) {
    if let index = commands.firstIndex(where: { $0.id == command.id }) {
      commands[index] = command
    } else {
      commands.append(command)
    }
  }
}

extension Workflow.Trigger {
  var isPassthrough: Bool {
    switch self {
    case .application:
      return false
    case .keyboardShortcuts(let trigger):
      return trigger.passthrough
    }
  }
}

extension Workflow {
  static func empty(id: String = UUID().uuidString) -> Workflow {
    Workflow(
      id: id,
      name: "Untitled workflow",
      trigger: nil,
      commands: []
    )
  }

  static func designTime(_ trigger: Trigger?) -> Workflow {
    Workflow(id: UUID().uuidString,
             name: "Workflow name",
             trigger: trigger,
    commands: [
      Command.empty(.application),
      Command.empty(.builtIn),
      Command.empty(.keyboard),
      Command.empty(.open),
      Command.empty(.script),
    ])
  }
}
