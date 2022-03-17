import Apps
import SwiftUI

struct EditCommandView: View {
  let imageSize = CGSize(width: 32, height: 32)
  @ObservedObject var applicationStore: ApplicationStore
  @ObservedObject var openPanelController: OpenPanelController
  let saveAction: (Command) -> Void
  let cancelAction: () -> Void
  @State var selection: Command?
  @State var command: Command
  private let commands: [Command]

  init(applicationStore: ApplicationStore,
       openPanelController: OpenPanelController,
       saveAction: @escaping (Command) -> Void,
       cancelAction: @escaping () -> Void,
       selection: Command?,
       command: Command) {
    self.applicationStore = applicationStore
    self.openPanelController = openPanelController
    self.saveAction = saveAction
    self.cancelAction = cancelAction
    self.commands = ModelFactory().commands(id: command.id)
    _command = .init(initialValue: command)
    _selection = .init(initialValue: command)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 0) {
        list.frame(width: 250)
        VStack {
          editView.frame(width: 450)
          Spacer()
          Divider()
          buttons.padding(8).frame(alignment: .bottom)
        }
      }.background(Color(.windowBackgroundColor))

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
        HStack {
          switch command {
          case .application:
            FeatureIcon(color: .red, size: imageSize) {
              AppSymbol()
                .fixedSize(horizontal: true, vertical: true)
                .padding()
            }
          case .script(let kind):
            switch kind {
            case .appleScript:
              FeatureIcon(color: .orange, size: imageSize, {
                ScriptSymbol(cornerRadius: 3,
                             foreground: .yellow,
                             background: .white.opacity(0.7),
                             borderColor: .white)
              }).redacted(reason: .placeholder)
            case .shell:
              FeatureIcon(color: .yellow, size: imageSize, {
                ScriptSymbol(cornerRadius: 3,
                             foreground: .yellow,
                             background: .white.opacity(0.7),
                             borderColor: .white)
              }).redacted(reason: .placeholder)
            }
          case .keyboard:
            FeatureIcon(color: .green, size: imageSize, {
              CommandSymbolIcon(background: .white.opacity(0.85), textColor: Color.green)
            }).redacted(reason: .placeholder)
          case .open(let kind):
            if !kind.isUrl {
              FeatureIcon(color: .blue, size: imageSize, {
                FolderSymbol(cornerRadius: 0.06, textColor: .blue)
              }).redacted(reason: .placeholder)
            } else {
              FeatureIcon(color: .purple, size: imageSize, {
                URLSymbol()
              }).redacted(reason: .placeholder)
            }
          case .type:
            FeatureIcon(color: .pink, size: imageSize, {
              TypingSymbol(foreground: Color.pink)
            }).redacted(reason: .placeholder)
          case .builtIn:
            FeatureIcon(color: .gray, size: imageSize, {
              Image(systemName: "tornado")
                .foregroundColor(Color.white)
            }).redacted(reason: .placeholder)
          }
          Text(command.name)
        }
        .tag(command.id)
        .frame(height: 36)
      }
    }
  }

  @ViewBuilder
  var editView: some View {
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

  private func receive(_ command: Command) {
    self.command = command
  }
}

struct EditCommandView_Previews: PreviewProvider {
  static let saloon = Saloon()
  static var previews: some View {
    EditCommandView(applicationStore: saloon.applicationStore,
                    openPanelController: OpenPanelController(),
                    saveAction: { _ in },
                    cancelAction: {},
                    selection: nil,
                    command: Command.application(ApplicationCommand(application: Application.finder())))
  }
}
