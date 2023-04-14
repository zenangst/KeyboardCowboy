import Foundation

extension Command {
  var fileLoggerValue: String {
    switch self {
    case .application:
      return "application(\(self.name):\(self.id))"
    case .builtIn:
      return "builtIn(\(self.name):\(self.id))"
    case .keyboard:
      return "keyboard(\(self.name):\(self.id))"
    case .open:
      return "open(\(self.name):\(self.id))"
    case .shortcut:
      return "shortcut(\(self.name):\(self.id))"
    case .script:
      return "script(\(self.name):\(self.id))"
    case .type:
      return "type(\(self.name):\(self.id))"
    case .systemCommand(let systemCommand):
      return "systemCommand:\(systemCommand.kind.rawValue)(\(self.name):\(self.id))"
    }
  }
}
