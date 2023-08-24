import Apps
import Foundation

enum NewCommandPayload: Equatable {
  case placeholder
  case script(value: String, kind: NewCommandScriptView.Kind, scriptExtension: NewCommandScriptView.ScriptExtension)
  case application(application: Application?, action: NewCommandApplicationView.ApplicationAction,
                   inBackground: Bool, hideWhenRunning: Bool, ifNotRunning: Bool)
  case url(targetUrl: URL, application: Application?)
  case open(path: String, application: Application?)
  case shortcut(name: String)
  case keyboardShortcut([KeyShortcut])
  case type(text: String, mode: TypeCommand.Mode)
  case systemCommand(kind: SystemCommand.Kind)
  case menuBar(tokens: [MenuBarCommand.Token])
  case windowManagement(kind: WindowCommand.Kind)

  var title: String {
    switch self {
    case .placeholder:
      return "Placeholder"
    case .script(_, let kind, let scriptExtension):
      switch scriptExtension {
      case .appleScript:
        switch kind {
        case .file:
          return "Run AppleScript"
        case .source:
          return "Run AppleScript"
        }
      case .shellScript:
        switch kind {
        case .file:
          return "Run Shell Script"
        case .source:
          return "Run Shell Script"
        }
      }
    case .application(let application, let action, _, _, _):
      let actionString: String
      switch action {
      case .open:
        actionString = "Open"
      case .close:
        actionString = "Close"
      }

      if let application {
        return "\(actionString) \(application.displayName)"
      } else {
        return "\(actionString) Application"
      }
    case .url(let targetUrl, let application):
      if let application {
        return "Open URL \(targetUrl.absoluteString) with \(application.displayName)"
      } else {
        return "Open URL \(targetUrl.absoluteString)"
      }
    case .open(let path, let application):
      if let application {
        return "Open \(path) with \(application.displayName)"
      } else {
        return "Open \(path)"
      }
    case .shortcut(let name):
      return "Run Shortcut '\(name)'"
    case .keyboardShortcut(let keyboardShortcuts):
      var keyboardShortcutString: String = "Run "
      for keyboardShortcut in keyboardShortcuts {
        keyboardShortcutString.append(keyboardShortcut.stringValue)
      }
      return keyboardShortcutString
    case .type:
      return "Input text"
    case .systemCommand:
      return "System Command"
    case .menuBar:
      return "MenuBar Command"
    case .windowManagement:
      return "Window Management Command"
    }
  }
}
