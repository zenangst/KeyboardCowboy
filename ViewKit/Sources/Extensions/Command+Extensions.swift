import ModelKit

extension Command {
  var icon: String {
    switch self {
    case .application(let applicationCommand):
      return applicationCommand.application.path
    case .script:
      return "/System/Applications/Utilities/Script Editor.app"
    case .keyboard:
      return "/System/Library/PreferencePanes/Keyboard.prefPane"
    case .open:
      return "/System/Library/CoreServices/Finder.app"
    }
  }
}
