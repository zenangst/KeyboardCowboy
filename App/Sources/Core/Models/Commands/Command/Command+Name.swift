import Foundation

extension Command {
  var name: String {
    get {
      switch self {
      case let .application(command): return command.name.isEmpty ? "\(command.action.displayValue) \(command.application.displayName)" : command.name
      case let .builtIn(command): return command.name
      case let .bundled(command): return command.name
      case let .keyboard(command):
        switch command.kind {
        case let .key(keyCommand):
          var keyboardShortcutString = ""
          keyCommand.keyboardShortcuts.forEach { keyboardShortcut in
            keyboardShortcutString += keyboardShortcut.modifiers.map(\.pretty).joined()
            keyboardShortcutString += keyboardShortcut.key
          }

          return command.name.isEmpty ? "Run a Keyboard Shortcut: \(keyboardShortcutString)" : command.name
        case let .inputSource(command):
          return command.name
        }
      case let .open(command):
        if !command.name.isEmpty { return command.name }
        if command.isUrl {
          return "Open a URL: \(command.path)"
        } else {
          return "Open a file: \(command.path)"
        }
      case let .shortcut(command): return command.name
      case let .script(command): return command.name
      case let .text(command): return command.name
      case let .systemCommand(command): return command.name
      case let .menuBar(command): return command.name
      case let .mouse(command): return command.name
      case let .uiElement(command): return command.name
      case let .windowFocus(command): return command.name
      case let .windowManagement(command): return command.name
      case let .windowTiling(command): return command.name
      }
    }
    set {
      switch self {
      case var .application(command):
        command.name = newValue
        self = .application(command)
      case var .builtIn(command):
        command.name = newValue
        self = .builtIn(command)
      case var .bundled(command):
        command.name = newValue
        self = .bundled(command)
      case var .keyboard(command):
        command.name = newValue
        self = .keyboard(command)
      case var .open(command):
        command.name = newValue
        self = .open(command)
      case var .script(command):
        command.name = newValue
        self = .script(command)
      case var .shortcut(command):
        command.name = newValue
        self = .shortcut(command)
      case var .text(command):
        command.name = newValue
        self = .text(command)
      case var .systemCommand(command):
        command.name = newValue
        self = .systemCommand(command)
      case var .menuBar(command):
        command.name = newValue
        self = .menuBar(command)
      case var .mouse(command):
        command.name = newValue
        self = .mouse(command)
      case var .uiElement(command):
        command.name = newValue
        self = .uiElement(command)
      case var .windowFocus(command):
        command.name = newValue
        self = .windowFocus(command)
      case var .windowManagement(command):
        command.name = newValue
        self = .windowManagement(command)
      case var .windowTiling(command):
        command.name = newValue
        self = .windowTiling(command)
      }
    }
  }
}
