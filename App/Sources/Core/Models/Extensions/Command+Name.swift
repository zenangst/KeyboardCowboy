import Foundation

extension Command {
  var name: String {
    get {
      switch self {
      case .application(let command):
        return command.name.isEmpty ? "\(command.action.displayValue) \(command.application.displayName)" : command.name
      case .builtIn(let command):
        return command.name
      case .keyboard(let command):
        var keyboardShortcutString: String = ""
        command.keyboardShortcuts.forEach { keyboardShortcut in
          keyboardShortcutString += keyboardShortcut.modifiers.map(\.pretty).joined()
          keyboardShortcutString += keyboardShortcut.key
        }

        return command.name.isEmpty ? "Run a Keyboard Shortcut: \(keyboardShortcutString)" : command.name
      case .open(let command):
        if !command.name.isEmpty { return command.name }
        if command.isUrl {
          return "Open a URL: \(command.path)"
        } else {
          return "Open a file: \(command.path)"
        }
      case .shortcut(let command):
        return "Run '\(command.shortcutIdentifier)'"
      case .script(let command):
        return command.name
      case .type(let command):
        return command.name
      case .systemCommand(let command):
        return command.name
      case .menuBar(let command):
        return command.name
      }
    }
    set {
      switch self {
      case .application(var command):
        command.name = newValue
        self = .application(command)
      case .builtIn:
        break
      case .keyboard(var command):
        command.name = newValue
        self = .keyboard(command)
      case .open(var command):
        command.name = newValue
        self = .open(command)
      case .script(let command):
        switch command {
        case .appleScript(let id, let isEnabled, _, let source):
          self = .script(.appleScript(id: id, isEnabled: isEnabled,
                                      name: newValue, source: source))
        case .shell(let id, let isEnabled, _, let source):
          self = .script(.shell(id: id, isEnabled: isEnabled,
                                name: newValue, source: source))
        }
      case .shortcut(var command):
        command.name = newValue
        self = .shortcut(command)
      case .type(var command):
        command.name = newValue
        self = .type(command)
      case .systemCommand(var command):
        command.name = newValue
        self = .systemCommand(command)
      case .menuBar(var command):
        command.name = newValue
        self = .menuBar(command)
      }
    }
  }
}
