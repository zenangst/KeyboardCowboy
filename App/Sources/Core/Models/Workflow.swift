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
    case modifier(ModifierTrigger)

    enum CodingKeys: String, CodingKey {
      case application
      case keyboardShortcuts
      case modifier
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
      case .modifier:
        let modifierTrigger = try container.decode(ModifierTrigger.self, forKey: .modifier)
        self = .modifier(modifierTrigger)
      case .snippet:
        let snippetTrigger = try container.decode(SnippetTrigger.self, forKey: .snippet)
        self = .snippet(snippetTrigger)
      case .none:
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "Unabled to decode enum.",
          ),
        )
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case let .application(trigger):
        try container.encode(trigger, forKey: .application)
      case let .keyboardShortcuts(keyboardShortcuts):
        try container.encode(keyboardShortcuts, forKey: .keyboardShortcuts)
      case let .modifier(modifierTrigger):
        try container.encode(modifierTrigger, forKey: .modifier)
      case let .snippet(trigger):
        try container.encode(trigger, forKey: .snippet)
      }
    }

    static func == (lhs: Trigger, rhs: Trigger) -> Bool {
      switch (lhs, rhs) {
      case let (.application(lhsTriggers), .application(rhsTriggers)):
        lhsTriggers == rhsTriggers
      case let (.keyboardShortcuts(lhsShortcuts), .keyboardShortcuts(rhsShortcuts)):
        lhsShortcuts == rhsShortcuts
      default:
        false
      }
    }
  }

  enum Execution: String, Hashable, Codable {
    case concurrent
    case serial
  }

  private(set) var id: String
  var commands: [Command] { didSet { generateMachPortComponents() } }
  var trigger: Trigger? { didSet { generateMachPortComponents() } }
  var isEnabled: Bool { !isDisabled }
  var isDisabled: Bool = false { didSet { generateMachPortComponents() } }
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
    isDisabled = !isEnabled
    self.execution = execution
    machPortConditions = MachPortConditions(
      id: id,
      trigger: trigger,
      execution: execution,
      isEnabled: !isDisabled,
      commands: commands,
    )
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString

    switch clone.trigger {
    case let .application(array):
      clone.trigger = .application(array.map { $0.copy() })
    case let .keyboardShortcuts(keyboardShortcutTrigger):
      clone.trigger = .keyboardShortcuts(keyboardShortcutTrigger.copy())
    case let .modifier(modifierTrigger):
      clone.trigger = .modifier(modifierTrigger.copy())
    case let .snippet(trigger):
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
    case isDisabled = "disabled"
    case execution
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    let name = try container.decode(String.self, forKey: .name)
    let commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
    let execution = try container.decodeIfPresent(Execution.self, forKey: .execution) ?? .concurrent
    let trigger = try container.decodeIfPresent(Trigger.self, forKey: .trigger)

    if let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) {
      isDisabled = !isEnabled
    } else if let isDisabled = try container.decodeIfPresent(Bool.self, forKey: .isDisabled) {
      self.isDisabled = isDisabled
    } else {
      isDisabled = false
    }

    self.id = id
    self.name = name
    self.commands = commands
    self.execution = execution
    self.trigger = trigger
    machPortConditions = MachPortConditions(
      id: id,
      trigger: trigger,
      execution: execution,
      isEnabled: !isDisabled,
      commands: commands,
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
    if let trigger {
      try container.encode(trigger, forKey: .trigger)
    }

    if isDisabled {
      try container.encode(isDisabled, forKey: .isDisabled)
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
    machPortConditions = MachPortConditions.from(self)
  }

  struct MachPortConditions: Hashable {
    let allowRepeat: Bool
    let enabledCommands: [Command]
    let enabledCommandsCount: Int
    let hasHoldForDelay: Bool
    let lastKeyIsAnyKey: Bool
    let keepLastPartialMatch: Bool
    let keyboardShortcutsTriggerCount: Int?
    let isEmpty: Bool
    let isPassthrough: Bool
    let isLeaderKey: Bool
    let isValidForRepeat: Bool
    let rebinding: KeyShortcut?
    let scheduleDuration: Double?
    let shouldRunOnKeyUp: Bool

    init(id _: String, trigger: Trigger?, execution _: Execution,
         isEnabled _: Bool, commands: [Command]) {
      let enabledCommands = commands.filter(\.isEnabled)
      self.enabledCommands = enabledCommands
      enabledCommandsCount = enabledCommands.count
      hasHoldForDelay = trigger.hasHoldForDelay
      isEmpty = enabledCommands.isEmpty
      isPassthrough = trigger.isPassthrough
      isValidForRepeat = enabledCommands.isValidForRepeat

      if case let .keyboardShortcuts(trigger) = trigger {
        lastKeyIsAnyKey = KeyShortcut.anyKey.key == trigger.shortcuts.last?.key
        keyboardShortcutsTriggerCount = trigger.shortcuts.count
        allowRepeat = trigger.allowRepeat
        keepLastPartialMatch = trigger.keepLastPartialMatch
        isLeaderKey = trigger.leaderKey

        if let holdDuration = trigger.holdDuration, trigger.shortcuts.count == 1, holdDuration > 0 {
          scheduleDuration = holdDuration
        } else {
          scheduleDuration = nil
        }
      } else {
        isLeaderKey = false
        allowRepeat = true
        keepLastPartialMatch = false
        keyboardShortcutsTriggerCount = nil
        lastKeyIsAnyKey = false
        scheduleDuration = nil
      }

      shouldRunOnKeyUp = enabledCommands.allSatisfy { command in
        switch command {
        case let .application(command):
          command.action == .peek
        case let .systemCommand(command):
          command.kind == .activateLastApplication
        case let .bundled(command):
          switch command.kind {
          case .activatePreviousWorkspace:
            true
          default:
            false
          }
        default: false
        }
      }

      if case let .keyboardShortcuts(shortcut) = trigger,
         shortcut.shortcuts.count == 1,
         commands.count == 1,
         case let .keyboard(keyboardCommand) = commands.first,
         case let .key(keyboardCommand) = keyboardCommand.kind,
         keyboardCommand.keyboardShortcuts.count == 1,
         let keyboardShortcut = keyboardCommand.keyboardShortcuts.last {
        rebinding = keyboardShortcut
      } else {
        rebinding = nil
      }
    }

    static func from(_ workflow: Workflow) -> MachPortConditions {
      MachPortConditions(
        id: workflow.id,
        trigger: workflow.trigger,
        execution: workflow.execution,
        isEnabled: !workflow.isDisabled,
        commands: workflow.commands,
      )
    }
  }
}

private extension Collection<Command> {
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
    case let .keyboardShortcuts(trigger): trigger.passthrough
    case .modifier: false
    case .none: false
    }
  }

  var hasHoldForDelay: Bool {
    switch self {
    case .none: false
    case .application: false
    case .snippet: false
    case .modifier: false
    case let .keyboardShortcuts(trigger):
      if let holdDurtion = trigger.holdDuration, holdDurtion > 0 {
        true
      } else {
        false
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
      execution: .serial,
      commands: [],
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
    var result = false
    let keywords = UserSpace.EnvironmentKey.allCases
      .map(\.asTextVariable)

    for command in commands {
      switch command {
      case .application, .builtIn, .mouse,
           .keyboard, .menuBar, .shortcut, .bundled,
           .systemCommand, .uiElement, .windowFocus, .windowManagement, .windowTiling:
        result = false
      case let .open(openCommand):
        result = openCommand.path.contains(keywords)
      case let .script(scriptCommand):
        switch scriptCommand.source {
        case let .path(string):
          result = string.contains(keywords)
        case let .inline(string):
          result = string.contains(keywords)
        }
      case let .text(textCommand):
        switch textCommand.kind {
        case let .insertText(typeCommand):
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
    var result = false
    for keyword in keywords {
      result = contains(keyword)
      if result { break }
    }
    return result
  }
}
