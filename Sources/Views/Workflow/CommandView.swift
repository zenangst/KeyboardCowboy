import Apps
import SwiftUI

struct CommandView: View {
  @Environment(\.colorScheme) var colorScheme
  @State var command: Command

  var body: some View {
    HStack(alignment: .center) {
      icon
        .frame(width: 36, height: 36)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        CommandActionsView()
      }
      Spacer()

      VStack {
        Toggle("", isOn: Binding<Bool>(get: { command.isEnabled },
                                       set: { command.isEnabled = $0 }))
          .toggleStyle(SwitchToggleStyle())
      }.font(Font.caption)

      Text("≣")
        .font(.title)
        .foregroundColor(Color(.secondaryLabelColor))
        .padding(.horizontal, 16)
        .offset(x: 0, y: -2)
    }
    .padding(4)
    .background(gradient)
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(.windowFrameTextColor), lineWidth: 1)
        .opacity(0.05)
    )
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

  var gradient: some View {
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
  }
}

struct CommandView_Previews: PreviewProvider {
  static var previews: some View {
    CommandView(command: Command.application(.init(application: Application.finder())))
  }
}
