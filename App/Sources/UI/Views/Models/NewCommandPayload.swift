import Apps
import Foundation

enum NewCommandPayload: Equatable {
  case placeholder
  case bundled(command: BundledCommand)
  case builtIn(builtIn: BuiltInCommand)
  case script(value: String, kind: NewCommandScriptView.Kind, scriptExtension: NewCommandScriptView.ScriptExtension)
  case application(application: Application?, action: NewCommandApplicationView.ApplicationAction,
                   inBackground: Bool, hideWhenRunning: Bool,
                   ifNotRunning: Bool, waitForAppToLaunch: Bool, addToStage: Bool)
  case url(targetUrl: URL, application: Application?)
  case open(path: String, application: Application?)
  case shortcut(name: String)
  case keyboardShortcut([KeyShortcut])
  case inputSource(id: String, name: String)
  case text(TextCommand)
  case systemCommand(kind: SystemCommand.Kind)
  case menuBar(tokens: [MenuBarCommand.Token], application: Application?)
  case mouse(kind: MouseCommand.Kind)
  case uiElement(predicates: [UIElementCommand.Predicate])
  case windowFocus(kind: WindowFocusCommand.Kind)
  case windowManagement(kind: WindowManagementCommand.Kind)
  case windowTiling(kind: WindowTiling)

  var title: String {
    switch self {
    case .placeholder:
      return "Placeholder"
    case let .builtIn(command):
      return command.kind.displayValue
    case let .script(_, kind, scriptExtension):
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
    case let .application(application, action, _, _, _, _, _):
      return switch action {
      case .open: "Open \(application?.displayName ?? "Application")"
      case .close: "Close \(application?.displayName ?? "Application")"
      case .hide: "Hide \(application?.displayName ?? "Application")"
      case .unhide: "Unhide \(application?.displayName ?? "Application")"
      case .peek: "Peek at \(application?.displayName ?? "Application")"
      }
    case let .url(targetUrl, application):
      return if let application {
        "Open URL \(targetUrl.absoluteString) with \(application.displayName)"
      } else {
        "Open URL \(targetUrl.absoluteString)"
      }
    case let .open(path, application):
      return if let application {
        "Open \(path) with \(application.displayName)"
      } else {
        "Open \(path)"
      }
    case let .shortcut(name):
      return "Run Shortcut '\(name)'"
    case let .keyboardShortcut(keyboardShortcuts):
      var keyboardShortcutString = "Run "
      for keyboardShortcut in keyboardShortcuts {
        keyboardShortcutString.append(keyboardShortcut.stringValue)
      }
      return keyboardShortcutString
    case .inputSource: return "Input Source"
    case .text: return "Text editing"
    case .systemCommand: return "System Command"
    case .menuBar: return "MenuBar Command"
    case .windowManagement: return "Window Management Command"
    case .mouse: return "Mouse Command"
    case .uiElement: return "UI Element Command"
    case .bundled: return "Bundled Command"
    case .windowFocus: return "Window Focus Command"
    case .windowTiling: return "Window Tiling Command"
    }
  }
}
