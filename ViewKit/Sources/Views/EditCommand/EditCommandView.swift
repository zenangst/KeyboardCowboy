import SwiftUI
import ModelKit

struct EditCommandView: View {
  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var openPanelController: OpenPanelController
  let saveAction: (Command) -> Void
  let cancelAction: () -> Void
  @State var selection: Command?
  @State var command: Command
  private let commands = ModelFactory().commands()

  var body: some View {
    HStack(spacing: 0) {
      list
        .listStyle(PlainListStyle())
        .frame(width: 250)
      VStack {
        editView
        Spacer()
        Divider()
        buttons.padding(8)
      }
      .frame(height: 300)
      .background(Color(.windowBackgroundColor))
    }
    .frame(width: 700)
  }
}

private extension EditCommandView {
  var list: some View {
    List(selection: $selection) {
      ForEach(commands) { command in
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

  var editView: some View {
    VStack(alignment: .center, spacing: 8) {
      VStack {
        switch selection {
        case .application(let command):
          EditApplicationCommandView(
            command: Binding(
              get: {
                if case .application(let model) = self.command {
                  return model
                } else {
                  return command
                }
              },
              set: { applicationCommand in
                self.command = .application(applicationCommand)
              }),
            installedApplications: applicationProvider.state)
        case .script(let kind):
          switch kind {
          case .appleScript:
            EditAppleScriptView(
              command: Binding(
                get: {
                  if case .script(let model) = self.command {
                    return model
                  } else {
                    return kind
                  }
                },
                set: { scriptCommand in
                  self.command = .script(scriptCommand)
                }),
              openPanelController: openPanelController)
          case .shell:
            EditShellScriptView(
              command: Binding(
                get: {
                  if case .script(let model) = self.command {
                    return model
                  } else {
                    return kind
                  }
                },
                set: { scriptCommand in
                  self.command = .script(scriptCommand)
                }),
              openPanelController: openPanelController)
          }
        case .open(let command):
          if command.isUrl {
            EditOpenURLCommandView(
              command: Binding(
                get: {
                  if case .open(let model) = self.command {
                    return model
                  } else {
                    return command
                  }
                },
                set: { openCommand in
                  self.command = .open(openCommand)
                }))
          } else {
            EditOpenFileCommandView(
              command: Binding(
                get: {
                  if case .open(let model) = self.command {
                    return model
                  } else {
                    return command
                  }
                },
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
              self.command = .keyboard(keyboardCommand)
            }
          ))
        case .none:
          Text("Pick a command type:")
        }
      }
    }
  }

  var buttons: some View {
    HStack {
      Spacer()
      Button(action: cancelAction, label: {
        Text("Cancel").frame(minWidth: 60)
      })
      Button(action: {
        saveAction(command)
      }, label: {
        Text("OK").frame(minWidth: 60)
      })
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
        EditCommandView(applicationProvider: ApplicationProviderMock().erase(),
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

private class ApplicationProviderMock: StateController {
  var state = [Application]()
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}
