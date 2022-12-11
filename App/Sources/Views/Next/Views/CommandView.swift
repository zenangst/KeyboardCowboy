import SwiftUI

struct CommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel

  init(_ command: Binding<DetailViewModel.CommandViewModel>) {
    _command = command
  }

  var body: some View {
    Group {
      switch command.kind {
      case .plain:
        UnknownView(command: $command)
      case .open:
        OpenCommandView(command: $command)
      case .application:
        ApplicationCommandView(command: $command)
      case .script:
        ScriptCommandView(command: $command)
      case .keyboard:
        RebindingCommandView(command: $command)
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
