import SwiftUI
import ModelKit

struct CommandView: View {
  let command: Command
  let editAction: (Command) -> Void
  let revealAction: (Command) -> Void
  let runAction: (Command) -> Void
  let showContextualMenu: Bool

  @ViewBuilder
  var body: some View {
    switch command {
    case .application:
      ApplicationView(command: command, editAction: editAction,
                      revealAction: revealAction, runAction: runAction,
                      showContextualMenu: showContextualMenu)
    case .builtIn:
      Text("This works!")
    case .script(let kind):
      switch kind {
      case .appleScript:
        AppleScriptView(command: command, editAction: editAction,
                        revealAction: revealAction, runAction: runAction,
                        showContextualMenu: showContextualMenu)
      case .shell:
        ShellScriptView(command: command, editAction: editAction,
                        revealAction: revealAction, runAction: runAction,
                        showContextualMenu: showContextualMenu)
      }
    case .open:
      OpenCommandView(command: command, editAction: editAction,
                      revealAction: revealAction, runAction: runAction,
                      showContextualMenu: showContextualMenu)
    case .keyboard:
      KeyboardCommandView(command: command,
                          editAction: editAction,
                          showContextualMenu: showContextualMenu)
    case .type:
      TypeCommandView(command: command, editAction: editAction,
                      showContextualMenu: showContextualMenu)
    }
  }
}
