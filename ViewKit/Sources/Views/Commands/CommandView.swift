import SwiftUI

struct CommandView: View {
  let command: CommandViewModel
  let editAction: (CommandViewModel) -> Void
  let revealAction: (CommandViewModel) -> Void
  let runAction: (CommandViewModel) -> Void
  let showContextualMenu: Bool

  var body: some View {
    switch command.kind {
    case .application:
      ApplicationView(command: command, editAction: editAction,
                      revealAction: revealAction, runAction: runAction,
                      showContextualMenu: showContextualMenu)
    case .appleScript:
      AppleScriptView(command: command, editAction: editAction,
                      revealAction: revealAction, runAction: runAction,
                      showContextualMenu: showContextualMenu)
    case .shellScript:
      ShellScriptView(command: command, editAction: editAction,
                      revealAction: revealAction, runAction: runAction,
                      showContextualMenu: showContextualMenu)
    case .openFile, .openUrl:
      OpenCommandView(command: command, editAction: editAction,
                      revealAction: revealAction,
                      showContextualMenu: showContextualMenu)
    case .keyboard:
      KeyboardCommandView(command: command,
                          editAction: editAction,
                          showContextualMenu: showContextualMenu)
    }
  }
}
