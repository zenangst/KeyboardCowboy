import SwiftUI
import ModelKit

struct EditCommandView: View {
  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var openPanelController: OpenPanelController
  let saveAction: (Command) -> Void
  let cancelAction: () -> Void
  @State var selection: Command?
  @State var command: Command
  private let commands: [Command]

  init(applicationProvider: ApplicationProvider,
       openPanelController: OpenPanelController,
       saveAction: @escaping (Command) -> Void,
       cancelAction: @escaping () -> Void,
       selection: Command?,
       command: Command) {
    self.applicationProvider = applicationProvider
    self.openPanelController = openPanelController
    self.saveAction = saveAction
    self.cancelAction = cancelAction
    self.commands = ModelFactory().commands(id: command.id)
    _command = .init(initialValue: command)
    _selection = .init(initialValue: selection)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 0) {
        list
          .frame(width: 250)
          .listStyle(PlainListStyle())
        VStack {
          editView
            .frame(width: 450)
        }
      }.background(Color(.windowBackgroundColor))

      Divider()
      buttons.padding(8)
    }
    .frame(height: 400)
  }
}

private extension EditCommandView {
  var list: some View {
    List(selection: Binding<Command?>(get: { selection }, set: { newCommand in
      if let newCommand = newCommand {
        command = newCommand
      }
      selection = newCommand
    }) ) {
      ForEach(commands, id: \.self) { command in
        CommandView(command: command,
                    editAction: { _ in },
                    revealAction: { _ in },
                    runAction: { _ in },
                    showContextualMenu: false)
          .padding(.horizontal, 4)
          .padding(.vertical, 8)
          .frame(height: 48)
          .tag(command)
      }
    }
  }

  @ViewBuilder
  var editView: some View {
      switch selection {
      case .application(let command):
        EditApplicationCommandView(
          command: Binding(
            get: { command },
            set: { applicationCommand in
              self.command = .application(applicationCommand)
            }),
          installedApplications: applicationProvider.state)
      case .script(let kind):
        switch kind {
        case .appleScript:
          EditAppleScriptView(
            command: Binding(
              get: { kind },
              set: { scriptCommand in
                self.command = .script(scriptCommand)
              }),
            openPanelController: openPanelController)
        case .shell:
          EditShellScriptView(
            command: Binding(
              get: { kind },
              set: { scriptCommand in
                self.command = .script(scriptCommand)
              }),
            openPanelController: openPanelController)
        }
      case .open(let command):
        if command.isUrl {
          EditOpenURLCommandView(
            command: Binding(
              get: { command },
              set: { openCommand in
                self.command = .open(openCommand)
              }))
        } else {
          EditOpenFileCommandView(
            command: Binding(
              get: { command },
              set: { openCommand in
                self.command = .open(openCommand)
              }),
            openPanelController: openPanelController)
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
      case .none:
        Text("Pick a command type")
          .padding()
      }
  }

  var buttons: some View {
    HStack {
      Spacer()
      Button(action: cancelAction, label: {
        Text("Cancel").frame(minWidth: 60)
      }).keyboardShortcut(.cancelAction)
      Button(action: {
        saveAction(command)
      }, label: {
        Text("OK").frame(minWidth: 60)
      }).keyboardShortcut(.defaultAction)
    }
  }
}

struct EditCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let models = [
      Command.application(.init(application: Application.empty())),
      Command.script(.appleScript(.path("path/to/applescript.scpt"), UUID().uuidString)),
      Command.script(.shell(.path("path/to/script.sh"), UUID().uuidString)),
      Command.keyboard(KeyboardCommand(keyboardShortcut: KeyboardShortcut.empty())),
      Command.open(OpenCommand(path: "http://www.github.com")),
      Command.open(OpenCommand.empty())
    ]

    return Group {
      ForEach(models) { model in
        EditCommandView(applicationProvider: ApplicationPreviewProvider().erase(),
                        openPanelController: OpenPanelPreviewController().erase(),
                        saveAction: { _ in },
                        cancelAction: {},
                        selection: model,
                        command: model)
          .previewDisplayName(model.name)
      }
    }
  }
}
