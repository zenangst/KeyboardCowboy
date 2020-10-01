import SwiftUI

struct CommandView: View {
  let command: CommandViewModel

  var body: some View {
    switch command.kind {
    case .application:
      ApplicationView(command: command)
    case .appleScript:
      AppleScriptView(command: command)
    case .shellScript:
      ShellScriptView(command: command)
    case .openFile, .openUrl:
      OpenCommandView(command: command)
    case .keyboard:
      KeyboardCommandView(command: command)
    }
  }
}
