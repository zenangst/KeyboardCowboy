import SwiftUI

struct CommandView: View {
  enum Action {
    case application(ApplicationCommandView.Action)
    case keyboard(KeyboardCommandView.Action)
    case open(OpenCommandView.Action)
    case script(ScriptCommandView.Action)
    case shortcut(ShortcutCommandView.Action)
    case type(TypeCommandView.Action)
  }
  @ObserveInjection var inject
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>, onAction: @escaping (Action) -> Void) {
    _command = command
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch command.kind {
      case .plain:
        UnknownView(command: $command)
      case .open:
        OpenCommandView($command, onAction: { onAction(.open($0)) })
      case .application:
        ApplicationCommandView($command, onAction: { onAction(.application($0)) })
      case .script:
        ScriptCommandView($command, onAction: { onAction(.script($0)) })
      case .keyboard:
        KeyboardCommandView($command, onAction: { onAction(.keyboard($0)) })
      case .shortcut:
        ShortcutCommandView($command, onAction: { onAction(.shortcut($0)) })
      case .type:
        TypeCommandView($command, onAction: { onAction(.type($0)) })
      }
    }
    .grayscale(command.isEnabled ? 0 : 0.5)
    .opacity(command.isEnabled ? 1 : 0.5)
    .background(Color(nsColor: NSColor.textBackgroundColor))
    .cornerRadius(8)
    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1),
            radius: command.isEnabled ? 4 : 2,
            y: command.isEnabled ? 2 : 0)
    .animation(.easeIn(duration: 0.2), value: command.isEnabled)
    .enableInjection()
  }

  var gradient: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(
          stops: [
            .init(color: Color(.textBackgroundColor).opacity(0.45), location: 0.75),
            .init(color: Color(.gridColor).opacity(0.55), location: 1.0),
          ]),
        startPoint: .top,
        endPoint: .bottom)

      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(nsColor: .shadowColor).opacity(0.5), lineWidth: 0.5)
        .offset(y: -1)
    }
  }
}
