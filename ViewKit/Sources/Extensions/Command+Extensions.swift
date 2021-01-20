import Cocoa
import ModelKit

extension Command {
  var icon: String {
    switch self {
    case .application(let applicationCommand):
      return applicationCommand.application.path
    case .builtIn(let command):
      switch command.kind {
      case .quickRun:
        return "ApplicationIcon"
      }
    case .script:
      return "/System/Applications/Utilities/Script Editor.app"
    case .keyboard, .type:
      return "/System/Library/PreferencePanes/Keyboard.prefPane"
    case .open(let openCommand):
      if openCommand.isUrl {
        if let applicationPath = openCommand.application?.path {
          return applicationPath
        } else if let url = URL(string: openCommand.path),
           let applicationUrl = NSWorkspace.shared.urlForApplication(toOpen: url),
           let applicationPath = (applicationUrl as NSURL).path {
          return applicationPath
        } else {
          return "/Applications/Safari.app"
        }
      } else {
        return openCommand.path
      }
    }
  }
}
