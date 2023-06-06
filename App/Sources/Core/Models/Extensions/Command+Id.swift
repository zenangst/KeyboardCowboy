import Foundation

extension Command {
  var id: String {
    get {
      switch self {
      case .application(let command):
        return command.id
      case .builtIn(let command):
        return command.id
      case .keyboard(let command):
        return command.id
      case .open(let command):
        return command.id
      case .script(let command):
        return command.id
      case .shortcut(let command):
        return command.id
      case .type(let command):
        return command.id
      case .systemCommand(let command):
        return command.id
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.id = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.id = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.id = newValue
        self = .keyboard(keyboardCommand)
      case .open(var openCommand):
        openCommand.id = newValue
        self = .open(openCommand)
      case .script(var scriptCommand):
        scriptCommand.id = newValue
        self = .script(scriptCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.id = newValue
        self = .shortcut(shortcutCommand)
      case .type(var typeCommand):
        typeCommand.id = newValue
        self = .type(typeCommand)
      case .systemCommand(var systemCommand):
        systemCommand.id = newValue
        self = .systemCommand(systemCommand)
      }
    }
  }
}
