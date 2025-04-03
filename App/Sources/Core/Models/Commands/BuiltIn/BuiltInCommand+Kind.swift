extension BuiltInCommand {
  enum Kind: Codable, Hashable, Identifiable, Sendable {
    enum Action: String, Codable, Hashable, Sendable {
      case enable
      case disable
      case toggle
    }

    case repeatLastWorkflow
    case macro(action: MacroAction)
    case userMode(mode: UserMode, action: Action)
    case commandLine(action: CommandLineAction)
    case windowSwitcher

    enum CodingKeys: CodingKey {
      case repeatLastWorkflow
      case macro
      case userMode
      case commandLine
      case windowSwitcher
    }

    var id: String {
      switch self {
      case .macro(let macro): macro.id
      case .userMode(let id, let action):
        switch action {
        case .enable: "enable-\(id)"
        case .disable: "disable-\(id)"
        case .toggle: "toggle-\(id)"
        }
      case .commandLine(let action): "commandLine-\(action.id)"
      case .repeatLastWorkflow:
        "repeat-last-workflow"
      case .windowSwitcher: "windowSwitcher"
      }
    }

    var userModeId: UserMode.ID {
      switch self {
      case .macro(let action): action.id
      case .userMode(let model, _): model.id
      case .commandLine(let action): action.id
      case .repeatLastWorkflow: id
      case .windowSwitcher: id
      }
    }

    public var displayValue: String {
      switch self {
      case .macro(let action):
        switch action.kind {
        case .remove:  "Remove Macro"
        case .record:  "Record Macro"
        }
      case .userMode(_, let action):
        switch action {
        case .enable:  "Enable User Mode"
        case .disable: "Disable User Mode"
        case .toggle:  "Toggle User Mode"
        }
      case .commandLine:   "Open Command Line"
      case .repeatLastWorkflow: "Repeat Last Workflow"
      case .windowSwitcher:  "Window Switcher"
      }
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: BuiltInCommand.Kind.CodingKeys.self)
      var allKeys = ArraySlice(container.allKeys)
      guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
        throw DecodingError.typeMismatch(BuiltInCommand.Kind.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
      }
      switch onlyKey {
      case .repeatLastWorkflow:
        self = BuiltInCommand.Kind.repeatLastWorkflow
      case .macro:
        let nestedContainer = try container.nestedContainer(keyedBy: BuiltInCommand.Kind.MacroCodingKeys.self, forKey: BuiltInCommand.Kind.CodingKeys.macro)
        self = BuiltInCommand.Kind.macro(action: try nestedContainer.decode(MacroAction.self, forKey: BuiltInCommand.Kind.MacroCodingKeys.action))
      case .userMode:
        let nestedContainer = try container.nestedContainer(keyedBy: BuiltInCommand.Kind.UserModeCodingKeys.self, forKey: BuiltInCommand.Kind.CodingKeys.userMode)
        self = BuiltInCommand.Kind.userMode(mode: try nestedContainer.decode(UserMode.self, forKey: BuiltInCommand.Kind.UserModeCodingKeys.mode), action: try nestedContainer.decode(BuiltInCommand.Kind.Action.self, forKey: BuiltInCommand.Kind.UserModeCodingKeys.action))
      case .commandLine:
        let nestedContainer = try container.nestedContainer(keyedBy: BuiltInCommand.Kind.CommandLineCodingKeys.self, forKey: BuiltInCommand.Kind.CodingKeys.commandLine)
        self = BuiltInCommand.Kind.commandLine(action: try nestedContainer.decode(CommandLineAction.self, forKey: BuiltInCommand.Kind.CommandLineCodingKeys.action))
      case .windowSwitcher:
        self = BuiltInCommand.Kind.windowSwitcher
      }
    }
  }
}
