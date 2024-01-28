import UniformTypeIdentifiers

extension UTType {
  static var group: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.Group", conformingTo: .json)
  }

  static var workflow: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.Workflows", conformingTo: .json)
  }

  static var command: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.Command", conformingTo: .json)
  }

  static var keyboardShortcut: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.KeyboardShortcut", conformingTo: .json)
  }

  static var applicationTrigger: UTType {
    UTType(exportedAs: "com.zenangst.Keyboard-Cowboy.ApplicationTrigger", conformingTo: .json)
  }
}
