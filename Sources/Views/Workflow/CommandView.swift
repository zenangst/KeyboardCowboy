import Apps
import SwiftUI

struct CommandView: View, Equatable {
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
        .frame(width: 36, height: 36)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        CommandActionsView(
          responder: responder,
          command: $command,
          action: { action in
            self.action(.commandAction(action))
          }
        )
      }
      Spacer()

      VStack {
        Toggle("", isOn: Binding<Bool>(get: { command.isEnabled },
                                       set: { command.isEnabled = $0 }))
          .toggleStyle(SwitchToggleStyle())
      }.font(Font.caption)

      Text("≣")
        .font(.title)
        .foregroundColor(Color(.windowFrameTextColor))
        .padding(.horizontal, 16)
        .offset(x: 0, y: -2)
    }
    .padding(4)
    .background(backgroundView)
    .opacity(!workflow.isEnabled ? 0.9 : command.isEnabled ? 1.0 : 0.8)
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
      RegularKeyIcon(letter: command.keyboardShortcut.key)
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
      ResponderBackgroundView(responder: responder, cornerRadius: 0)
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
