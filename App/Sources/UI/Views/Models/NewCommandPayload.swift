import Apps
import Foundation

enum NewCommandPayload: Equatable {
  case placeholder
  case builtIn(builtIn: BuiltInCommand)
  case script(value: String, kind: NewCommandScriptView.Kind, scriptExtension: NewCommandScriptView.ScriptExtension)
  case application(application: Application?, action: NewCommandApplicationView.ApplicationAction,
                   inBackground: Bool, hideWhenRunning: Bool, ifNotRunning: Bool)
  case url(targetUrl: URL, application: Application?)
  case open(path: String, application: Application?)
  case shortcut(name: String)
  case keyboardShortcut([KeyShortcut])
  case text(TextCommand)
  case systemCommand(kind: SystemCommand.Kind)
  case menuBar(tokens: [MenuBarCommand.Token], application: Application?)
  case mouse(kind: MouseCommand.Kind)
  case uiElement(predicates: [UIElementCommand.Predicate])
  case windowManagement(kind: WindowCommand.Kind)

  var title: String {
    switch self {
    case .placeholder:
      return "Placeholder"
    case .builtIn(let command):
      return command.kind.displayValue
    case .script(_, let kind, let scriptExtension):
      switch scriptExtension {
      case .appleScript:
        return switch kind {
        case .file: "Run AppleScript"
        case .source: "Run AppleScript"
        }
      case .shellScript:
        return switch kind {
        case .file: "Run Shell Script"
        case .source: "Run Shell Script"
        }
      }
    case .application(let application, let action, _, _, _):
      return switch action {
      case .open:  "Open \(application?.displayName ?? "Application")"
      case .close: "Close \(application?.displayName ?? "Application")"
      case .hide:  "Hide \(application?.displayName ?? "Application")"
      case .unhide:  "Unhide \(application?.displayName ?? "Application")"
      }
    case .url(let targetUrl, let application):
      return if let application {
        "Open URL \(targetUrl.absoluteString) with \(application.displayName)"
      } else {
        "Open URL \(targetUrl.absoluteString)"
      }
    case .open(let path, let application):
      return if let application {
        "Open \(path) with \(application.displayName)"
      } else {
        "Open \(path)"
      }
    case .shortcut(let name):
      return "Run Shortcut '\(name)'"
    case .keyboardShortcut(let keyboardShortcuts):
      var keyboardShortcutString: String = "Run "
      for keyboardShortcut in keyboardShortcuts {
        keyboardShortcutString.append(keyboardShortcut.stringValue)
      }
      return keyboardShortcutString
    case .text:
      return "Text editing"
    case .systemCommand:
      return "System Command"
    case .menuBar:
      return "MenuBar Command"
    case .windowManagement:
      return "Window Management Command"
    case .mouse:
      return "Mouse Command"
    case .uiElement:
      return "UI Element Command"
    }
  }
}
