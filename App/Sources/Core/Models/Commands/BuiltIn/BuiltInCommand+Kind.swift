extension BuiltInCommand {
  enum Kind: Codable, Hashable, Identifiable, Sendable {
    enum Action: String, Codable, Hashable, Sendable {
      case enable
      case disable
      case toggle
    }

    case repeatLastWorkflow
    case macro(MacroAction)
    case userMode(UserMode, Action)
    case commandLine(CommandLineAction)
    case windowSwitcher

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
  }
}
