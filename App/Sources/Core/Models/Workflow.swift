import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
struct Workflow: Identifiable, Equatable, Codable, Hashable, Sendable {
  enum Trigger: Hashable, Equatable, Codable, Sendable {
    case application([ApplicationTrigger])
    case keyboardShortcuts(KeyboardShortcutTrigger)
    case snippet(SnippetTrigger)

    enum CodingKeys: String, CodingKey {
      case application
      case keyboardShortcuts
      case snippet
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
          Task {
            await MainActor.run { Migration.shouldSave = true }
          }
          let keyboardShortcuts = try container.decode([KeyShortcut].self, forKey: .keyboardShortcuts)
          self = .keyboardShortcuts(.init(shortcuts: keyboardShortcuts))
        }
      case .snippet:
        let snippetTrigger = try container.decode(SnippetTrigger.self, forKey: .snippet)
        self = .snippet(snippetTrigger)
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
      case .snippet(let trigger):
        try container.encode(trigger, forKey: .snippet)
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
  var commands: [Command]  { didSet { generateMachPortComponents() } }
  var trigger: Trigger?  { didSet { generateMachPortComponents() } }
  var isEnabled: Bool = true  { didSet { generateMachPortComponents() } }
  var name: String
  var execution: Execution { didSet { generateMachPortComponents() } }

  var isRebinding: Bool {
    if commands.count == 1, case .keyboard = commands.first { return true }
    return false
  }

  var machPortConditions: MachPortConditions

  init(id: String = UUID().uuidString, name: String,
       trigger: Trigger? = nil,
       execution: Execution = .concurrent,
       isEnabled: Bool = true,
       commands: [Command] = []) {
    self.id = id
    self.commands = commands
    self.trigger = trigger
    self.name = name
    self.isEnabled = isEnabled
    self.execution = execution
    self.machPortConditions = MachPortConditions(
      id: id,
      trigger: trigger,
      execution: execution,
      isEnabled: isEnabled,
      commands: commands
    )
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString

    switch clone.trigger {
    case .application(let array):
      clone.trigger = .application(array.map { $0.copy() })
    case .keyboardShortcuts(let keyboardShortcutTrigger):
      clone.trigger = .keyboardShortcuts(keyboardShortcutTrigger.copy())
    case .snippet(let trigger):
      clone.trigger = .snippet(trigger.copy())
    case .none:
      break
    }

    clone.commands = clone.commands.map { $0.copy() }

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

    let id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    let name = try container.decode(String.self, forKey: .name)
    let commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
    let execution = try container.decodeIfPresent(Execution.self, forKey: .execution) ?? .concurrent
    let trigger = try container.decodeIfPresent(Trigger.self, forKey: .trigger)
    let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true

    self.id = id
    self.name = name
    self.commands = commands
    self.execution = execution
    self.trigger = trigger
    self.isEnabled = isEnabled
    self.machPortConditions = MachPortConditions(
      id: id,
      trigger: trigger,
      execution: execution,
      isEnabled: isEnabled,
      commands: commands
    )
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

  private mutating func generateMachPortComponents() {
    self.machPortConditions = MachPortConditions.from(self)
  }

  struct MachPortConditions: Hashable {
    let enabledCommands: [Command]
    let enabledCommandsCount: Int
    let hasHoldForDelay: Bool
    let lastKeyIsAnyKey: Bool
    let keyboardShortcutsTriggerCount: Int?
    let isEmpty: Bool
    let isPassthrough: Bool
    let isValidForRepeat: Bool
    let rebinding: KeyShortcut?
    let scheduleDuration: Double?
    let shouldRunOnKeyUp: Bool

    init(id: String, trigger: Trigger?, execution: Execution,
         isEnabled: Bool, commands: [Command]) {
      let enabledCommands = commands.filter(\.isEnabled)
      self.enabledCommands = enabledCommands
      self.enabledCommandsCount = enabledCommands.count
      self.hasHoldForDelay = trigger.hasHoldForDelay
      self.isEmpty = enabledCommands.isEmpty
      self.isPassthrough = trigger.isPassthrough
      self.isValidForRepeat = enabledCommands.isValidForRepeat
      
      if case .keyboardShortcuts(let trigger) = trigger {
        self.lastKeyIsAnyKey = KeyShortcut.anyKey.key == trigger.shortcuts.last?.key
        self.keyboardShortcutsTriggerCount = trigger.shortcuts.count

        if let holdDuration = trigger.holdDuration, trigger.shortcuts.count == 1, holdDuration > 0 {
          self.scheduleDuration = holdDuration
        } else {
          self.scheduleDuration = nil
        }
      } else {
        self.keyboardShortcutsTriggerCount = nil
        self.lastKeyIsAnyKey = false
        self.scheduleDuration = nil
      }

      self.shouldRunOnKeyUp = enabledCommands.allSatisfy({ command in
        switch command {
        case .application(let command):
          return command.action == .peek
        default: return false
        }
      })

      if case .keyboardShortcuts(let shortcut) = trigger,
         shortcut.shortcuts.count == 1,
         commands.count == 1,
         case .keyboard(let keyboardCommand) = commands.first,
         keyboardCommand.keyboardShortcuts.count == 1,
         let keyboardShortcut = keyboardCommand.keyboardShortcuts.last {
        self.rebinding = keyboardShortcut
      } else {
        self.rebinding = nil
      }
    }

    static func from(_ workflow: Workflow) -> MachPortConditions {
      MachPortConditions(
        id: workflow.id,
        trigger: workflow.trigger,
        execution: workflow.execution,
        isEnabled: workflow.isEnabled,
        commands: workflow.commands
      )
    }
  }
}

private extension Collection where Element == Command {
  var isValidForRepeat: Bool {
    allSatisfy { element in
      switch element {
      case .keyboard, .menuBar, .windowManagement: true
      default: false
      }
    }
  }
}

private extension Workflow.Trigger? {
  var isPassthrough: Bool {
    switch self {
    case .application: false
    case .snippet: true
    case .keyboardShortcuts(let trigger): trigger.passthrough
    case .none: false
    }
  }

  var hasHoldForDelay: Bool {
    switch self {
    case .none: return false
    case .application: return false
    case .snippet: return false
    case .keyboardShortcuts(let trigger):
      if let holdDurtion = trigger.holdDuration, holdDurtion > 0 {
        return true
      } else {
        return false
      }
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

extension Workflow {
  func resolveUserEnvironment() -> Bool {
    var result: Bool = false
    let keywords = UserSpace.EnvironmentKey.allCases
      .map(\.asTextVariable)

    for command in commands {
      switch command {
      case .application, .builtIn, .mouse, 
           .keyboard, .menuBar, .shortcut, .bundled,
           .systemCommand, .uiElement, .windowManagement:
        result = false
      case .open(let openCommand):
        result = openCommand.path.contains(keywords)
      case .script(let scriptCommand):
        switch scriptCommand.source {
        case .path(let string):
          result = string.contains(keywords)
        case .inline(let string):
          result = string.contains(keywords)
        }
      case .text(let textCommand):
        switch textCommand.kind {
        case .insertText(let typeCommand):
          result = typeCommand.input.contains(keywords)
        }
      }
      if result { break }
    }

    return result
  }
}

private extension String {
  func contains(_ keywords: [String]) -> Bool {
    var result: Bool = false
    for keyword in keywords {
      result = self.contains(keyword)
      if result { break }
    }
    return result
  }
}

