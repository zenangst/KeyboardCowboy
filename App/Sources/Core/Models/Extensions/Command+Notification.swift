import Foundation

extension Command {
  var notification: Bool {
    get {
      switch self {
      case .application(let applicationCommand):
        return applicationCommand.notification
      case .builtIn(let builtInCommand):
        return builtInCommand.notification
      case .keyboard(let keyboardCommand):
        return keyboardCommand.notification
      case .open(let openCommand):
        return openCommand.notification
      case .script:
        // TODO: Add support for `.notification` on script commands.
        return false
        //        return scriptCommand.notification
      case .shortcut(let shortcutCommand):
        return shortcutCommand.notification
      case .type(let typeCommand):
        return typeCommand.notification
      case .systemCommand(let systemCommand):
        return systemCommand.notification
      case .menuBar(let menuCommand):
        return menuCommand.notification
      }
    }
    set {
      switch self {
      case .application(var applicationCommand):
        applicationCommand.notification = newValue
        self = .application(applicationCommand)
      case .builtIn(var builtInCommand):
        builtInCommand.notification = newValue
        self = .builtIn(builtInCommand)
      case .keyboard(var keyboardCommand):
        keyboardCommand.notification = newValue
        self = .keyboard(keyboardCommand)
      case .open(var openCommand):
        openCommand.notification = newValue
        self = .open(openCommand)
      case .script(var scriptCommand):
        // TODO: Add support for notification on script command
        //        scriptCommand.notification = newValue
        self = .script(scriptCommand)
      case .shortcut(var shortcutCommand):
        shortcutCommand.notification = newValue
        self = .shortcut(shortcutCommand)
      case .type(var typeCommand):
        typeCommand.notification = newValue
        self = .type(typeCommand)
      case .systemCommand(var systemCommand):
        systemCommand.notification = newValue
        self = .systemCommand(systemCommand)
      case .menuBar(var menuBarCommand):
        menuBarCommand.notification = newValue
        self = .menuBar(menuBarCommand)
      }
    }
  }
}
