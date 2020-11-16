import ModelKit

extension Command {
  var icon: Icon {
    let icon: Icon
    switch self {
    case .application(let applicationCommand):
      icon = Icon(identifier: applicationCommand.application.bundleIdentifier,
                          path: applicationCommand.application.path)
    case .script:
      icon = Icon(identifier: "com.apple.ScriptEditor2",
                          path: "/System/Applications/Utilities/Script Editor.app")
    case .keyboard:
      icon = Icon(identifier: "com.apple.preference.keyboard",
                          path: "/System/Library/PreferencePanes/Keyboard.prefPane")
    case .open:
      icon = Icon(identifier: "com.apple.finder",
                          path: "/System/Library/CoreServices/Finder.app")
    }

    return icon
  }
}
