import Foundation

extension Command {
  var isEnabled: Bool {
    get {
      switch self {
      case .application(let applicationCommand):
        return applicationCommand.isEnabled
      case .builtIn(let builtInCommand):
        return builtInCommand.isEnabled
      case .keyboard(let keyboardCommand):
        return keyboardCommand.isEnabled
      case .open(let openCommand):
        return openCommand.isEnabled
      case .script(let scriptCommand):
        return scriptCommand.isEnabled
      case .shortcut(let shortcutCommand):
        return shortcutCommand.isEnabled
      case .type(let typeCommand):
        return typeCommand.isEnabled
      case .systemCommand(let systemCommand):
        return systemCommand.isEnabled
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.isEnabled = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.isEnabled = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.isEnabled = newValue
        self = .keyboard(keyboardCommand)
      case .open(var openCommand):
        openCommand.isEnabled = newValue
        self = .open(openCommand)
      case .script(var scriptCommand):
        scriptCommand.isEnabled = newValue
        self = .script(scriptCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.isEnabled = newValue
        self = .shortcut(shortcutCommand)
      case .type(var typeCommand):
        typeCommand.isEnabled = newValue
        self = .type(typeCommand)
      case .systemCommand(var systemCommand):
        systemCommand.isEnabled = newValue
        self = .systemCommand(systemCommand)
      }
    }
  }
}
