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
      }
    }
    .grayscale(command.isEnabled ? 0 : 1)
    .opacity(command.isEnabled ? 1 : 0.5)
    .background(gradient)
    .cornerRadius(8)
    .enableInjection()
  }

  var gradient: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(
          stops: [
            .init(color: Color(.textBackgroundColor).opacity(0.45), location: 0.5),
            .init(color: Color(.gridColor).opacity(0.85), location: 1.0),
          ]),
        startPoint: .top,
        endPoint: .bottom)

      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(nsColor: .shadowColor).opacity(0.5), lineWidth: 0.5)
        .offset(y: -1)
    }
  }
}
