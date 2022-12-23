import SwiftUI

struct CommandView: View {
  enum Action {
    case application(action: ApplicationCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case keyboard(action: KeyboardCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case open(action: OpenCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case script(action: ScriptCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case shortcut(action: ShortcutCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case type(action: TypeCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
  }
  @ObserveInjection var inject
  let workflowId: String
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       workflowId: String,
       onAction: @escaping (Action) -> Void) {
    _command = command
    self.workflowId = workflowId
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch command.kind {
      case .plain:
        UnknownView(command: $command)
      case .open:
        OpenCommandView(
          $command,
          onAction: { onAction(.open(action: $0, workflowId: workflowId, commandId: command.id)) })
      case .application(let action, let inBackground, let hideWhenRunning, let ifNotRunning):
        ApplicationCommandView(
          $command,
          actionName: action,
          inBackground: inBackground,
          hideWhenRunning: hideWhenRunning,
          ifNotRunning: ifNotRunning,
          onAction: { onAction(.application(action: $0, workflowId: workflowId, commandId: command.id)) })
      case .script:
        ScriptCommandView(
          $command,
          onAction: { onAction(.script(action: $0, workflowId: workflowId, commandId: command.id)) })
      case .keyboard:
        KeyboardCommandView(
          $command,
          onAction: { onAction(.keyboard(action: $0, workflowId: workflowId, commandId: command.id)) })
      case .shortcut:
        ShortcutCommandView(
          $command,
          onAction: { onAction(.shortcut(action: $0, workflowId: workflowId, commandId: command.id)) })
      case .type:
        TypeCommandView(
          $command,
          onAction: { onAction(.type(action: $0, workflowId: workflowId, commandId: command.id)) })
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
