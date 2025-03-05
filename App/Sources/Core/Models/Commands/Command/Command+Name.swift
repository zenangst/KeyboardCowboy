import Foundation

extension Command {
  var name: String {
    get {
      switch self {
      case .application(let command): return command.name.isEmpty ? "\(command.action.displayValue) \(command.application.displayName)" : command.name
      case .builtIn(let command): return command.name
      case .bundled(let command): return command.name
      case .keyboard(let command):
        switch command.kind {
        case .key(let keyCommand):
          var keyboardShortcutString: String = ""
          keyCommand.keyboardShortcuts.forEach { keyboardShortcut in
            keyboardShortcutString += keyboardShortcut.modifiers.map(\.pretty).joined()
            keyboardShortcutString += keyboardShortcut.key
          }

          return command.name.isEmpty ? "Run a Keyboard Shortcut: \(keyboardShortcutString)" : command.name
        case .inputSource:
          return "Switch Input Source"
        }
      case .open(let command):
        if !command.name.isEmpty { return command.name }
        if command.isUrl {
          return "Open a URL: \(command.path)"
        } else {
          return "Open a file: \(command.path)"
        }
      case .shortcut(let command):         return command.name
      case .script(let command):           return command.name
      case .text(let command):             return command.name
      case .systemCommand(let command):    return command.name
      case .menuBar(let command):          return command.name
      case .mouse(let command):            return command.name
      case .uiElement(let command):        return command.name
      case .windowFocus(let command):      return command.name
      case .windowManagement(let command): return command.name
      case .windowTiling(let command):     return command.name
      }
    }
    set {
      switch self {
      case .application(var command):
        command.name = newValue
        self = .application(command)
      case .builtIn(var command):
        command.name = newValue
        self = .builtIn(command)
      case .bundled(var command):
        command.name = newValue
        self = .bundled(command)
      case .keyboard(var command):
        command.name = newValue
        self = .keyboard(command)
      case .open(var command):
        command.name = newValue
        self = .open(command)
      case .script(var command):
        command.name = newValue
        self = .script(command)
      case .shortcut(var command):
        command.name = newValue
        self = .shortcut(command)
      case .text(var command):
        command.name = newValue
        self = .text(command)
      case .systemCommand(var command):
        command.name = newValue
        self = .systemCommand(command)
      case .menuBar(var command):
        command.name = newValue
        self = .menuBar(command)
      case .mouse(var command):
        command.name = newValue
        self = .mouse(command)
      case .uiElement(var command):
        command.name = newValue
        self = .uiElement(command)
      case .windowFocus(var command):
        command.name = newValue
        self = .windowFocus(command)
      case .windowManagement(var command):
        command.name = newValue
        self = .windowManagement(command)
      case .windowTiling(var command):
        command.name = newValue
        self = .windowTiling(command)
      }
    }
  }
}
