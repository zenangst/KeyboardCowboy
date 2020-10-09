import SwiftUI

struct EditCommandView: View {
  @ObservedObject var applicationProvider: ApplicationProvider
  @ObservedObject var openPanelController: OpenPanelController
  let saveAction: (CommandViewModel) -> Void
  let cancelAction: () -> Void
  @State var selection: CommandViewModel.Kind?
  @State var commandViewModel: CommandViewModel
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
          .tag(command.kind)
      }
    }
  }

  var editView: some View {
    VStack(alignment: .center, spacing: 8) {
      VStack {
        switch selection {
        case .application:
          EditApplicationCommandView(
            commandViewModel: Binding(get: { commandViewModel },
                                      set: { commandViewModel = $0 }),
            installedApplications: applicationProvider.state)
        case .appleScript:
          EditAppleScriptView(
            commandViewModel: Binding(get: { commandViewModel },
                                      set: { commandViewModel = $0 }),
            openPanelController: openPanelController)
        case .keyboard:
          EditKeyboardShortcutView(
            commandViewModel: Binding(get: { commandViewModel },
                                      set: { commandViewModel = $0 }),
            openPanelController: openPanelController)
        case .openFile:
          EditOpenFileCommandView(
            commandViewModel: Binding(get: { commandViewModel },
                                      set: { commandViewModel = $0 }),
            openPanelController: openPanelController)
        case .openUrl:
          EditOpenURLCommandView(
            commandViewModel: Binding(get: { commandViewModel },
                                      set: { commandViewModel = $0 }))
        case .shellScript:
          EditShellScriptView(
            commandViewModel: Binding(get: { commandViewModel },
                                      set: { commandViewModel = $0 }),
            openPanelController: openPanelController)
        default:
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
        saveAction(commandViewModel)
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
      CommandViewModel(id: UUID().uuidString, name: "Application",
                       kind: .application(ApplicationViewModel.empty())),
      CommandViewModel(id: UUID().uuidString, name: "Apple script",
                       kind: .appleScript(AppleScriptViewModel.empty())),
      CommandViewModel(id: UUID().uuidString, name: "Keyboard shortcut",
                       kind: .keyboard(KeyboardShortcutViewModel.empty())),
      CommandViewModel(id: UUID().uuidString, name: "Open file",
                       kind: .openFile(OpenFileViewModel.empty())),
      CommandViewModel(id: UUID().uuidString, name: "Open Url",
                       kind: .openUrl(OpenURLViewModel.empty())),
      CommandViewModel(id: UUID().uuidString, name: "Run Shell script",
                       kind: .shellScript(ShellScriptViewModel.empty()))
    ]

    return Group {
      ForEach(models) { model in
        EditCommandView(applicationProvider: ApplicationProviderMock().erase(),
                        openPanelController: OpenPanelPreviewController().erase(),
                        saveAction: { _ in },
                        cancelAction: {},
                        selection: model.kind,
                        commandViewModel: model)
          .previewDisplayName(model.name)
      }
    }
  }
}

private class ApplicationProviderMock: StateController {
  var state = [ApplicationViewModel]()
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}
