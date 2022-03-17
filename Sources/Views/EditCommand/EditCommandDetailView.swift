import SwiftUI

struct EditCommandDetailView: View {
  @ObservedObject var applicationStore: ApplicationStore
  @ObservedObject var openPanelController: OpenPanelController
  @Binding var selection: Command?
  @Binding var command: Command

  var body: some View {
    switch selection {
    case .application(let command):
      EditApplicationCommandView(
        command: command,
        applicationStore: applicationStore) { applicationCommand in
          self.command = .application(applicationCommand)
        }
    case .script(let kind):
      switch kind {
      case .appleScript(let id, let isEnabled, let name, let source):
        EditAppleScriptView(
          command: ScriptCommand.appleScript(id: id, isEnabled: isEnabled, name: name, source: source),
          openPanelController: openPanelController) { scriptCommand in
            self.command = .script(scriptCommand)
          }
      case .shell(let id, let isEnabled, let name, let source):
        EditShellScriptView(
          command: ScriptCommand.shell(id: id, isEnabled: isEnabled, name: name, source: source),
          openPanelController: openPanelController) { scriptCommand in
            self.command = .script(scriptCommand)
          }
      }
    case .open(let command):
      if command.isUrl {
        EditOpenURLCommandView(
          command: command,
          installedApplications: applicationStore.applications) { openCommand in
            self.command = .open(openCommand)
          }
      } else {
        EditOpenFileCommandView(
          command: command,
          openPanelController: openPanelController,
          installedApplications: applicationStore.applications) { openCommand in
            self.command = .open(openCommand)
          }
      }
      EmptyView()
    case .keyboard(let command):
      EditKeyboardShortcutView(command: Binding(
        get: { command },
        set: { keyboardCommand in
          let command: Command = .keyboard(keyboardCommand)
          self.command = command
          self.selection = command
        }
      ))
    case .type(let command):
      EditTypeView(command: Binding(
        get: { command },
        set: { typeCommand in
          let command: Command = .type(typeCommand)
          self.command = command
          self.selection = command
        }
      ))
    case .builtIn(let command):
      EditBuiltInCommand(command: command) { builtInCommand in
        let command: Command = .builtIn(builtInCommand)
        self.command = command
        self.selection = command
      }
    case .none:
      Text("Pick a command type")
        .padding()
    }

  }
}

struct EditCommandDetailView_Previews: PreviewProvider {
  static let command = Command.empty(.application)
  static var previews: some View {
    EditCommandDetailView(applicationStore: applicationStore,
                          openPanelController: OpenPanelController(),
                          selection: .constant(command),
                          command: .constant(command))
  }
}
