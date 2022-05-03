import Apps
import SwiftUI

struct CommandView: View, Equatable {
  @ObserveInjection var inject
  enum Action {
    case commandAction(CommandActionsView.Action)
  }
  @Environment(\.colorScheme) var colorScheme
  @Binding var workflow: Workflow
  @Binding var command: Command
  @ObservedObject var responder: Responder

  var action: (Action) -> Void

  var body: some View {
    HStack(alignment: .center) {
      icon
        .frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        CommandActionsView(
          responder,
          command: $command,
          features: CommandActionsView.Feature.allCases,
          action: { action in
            self.action(.commandAction(action))
          }
        )
      }
      Spacer()
      VStack {
        Toggle("", isOn: $command.isEnabled)
          .toggleStyle(SwitchToggleStyle())
      }
      .font(Font.caption)
    }
    .padding([.top, .bottom], 4)
    .padding([.leading, .trailing], 8)
    .background(backgroundView)
    .opacity(!workflow.isEnabled ? 0.9 : command.isEnabled ? 1.0 : 0.8)
    .enableInjection()
  }

  static func ==(lhs: CommandView, rhs: CommandView) -> Bool {
    lhs.command == rhs.command
  }

  @ViewBuilder
  var icon: some View {
    switch command {
    case .application(let applicationCommand):
      IconView(path: applicationCommand.application.path)
    case .builtIn:
      Spacer()
    case .keyboard(let command):
      RegularKeyIcon(letter: command.keyboardShortcut.key,
                     width: 32,
                     height: 32,
                     alignment: .center,
                     glow: .constant(false))
    case .open(let command):
      if let application = command.application {
        IconView(path: application.path)
          .frame(width: 32, height: 32)
      } else if command.isUrl {
        IconView(path: "/Applications/Safari.app")
          .frame(width: 32, height: 32)
      } else {
        IconView(path: command.path)
          .frame(width: 32, height: 32)
      }
    case .script(let command):
      switch command {
      case .appleScript:
        IconView(path: "/System/Applications/Utilities/Script Editor.app")
      case .shell:
        IconView(path: "/System/Applications/Utilities/Terminal.app")
      }
    case .shortcut:
      IconView(path: "/System/Applications/Shortcuts.app")
    case .type:
      Spacer()
    }
  }

  @ViewBuilder
  var backgroundView: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(
          stops:
            colorScheme == .dark
          ? [.init(color: Color(.gridColor).opacity(0.25), location: 0.33),
             .init(color: Color(.gridColor).opacity(0.4), location: 1.0)]
          : [.init(color: Color(.textBackgroundColor).opacity(1), location: 0.0),
             .init(color: Color(.textBackgroundColor).opacity(0.75), location: 1.0)]
        ),
        startPoint: .top,
        endPoint: .bottom)
      ResponderBackgroundView(responder: responder, cornerRadius: 8)
    }
  }
}

struct CommandView_Previews: PreviewProvider {
  static var previews: some View {
    CommandView(
      workflow: .constant(Workflow.empty()),
      command: .constant(Command.application(.init(application: Application.finder()))),
      responder: Responder(),
      action: { _ in })
  }
}
