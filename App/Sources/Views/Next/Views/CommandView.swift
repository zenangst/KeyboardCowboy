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
  @State private var progressValue: CGFloat = 0.0
  @State private var progressAlpha: CGFloat = 0.0
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       workflowId: String,
       onAction: @escaping (Action) -> Void) {
    _command = command
    self.workflowId = workflowId
    self.onAction = onAction
  }

  var body: some View {
    ZStack {
      switch command.kind {
      case .plain:
        UnknownView(command: $command)
      case .open:
        OpenCommandView(
          $command,
          onAction: { action in
            let newAction: Action = .open(action: action, workflowId: workflowId, commandId: command.id)
            onAction(newAction)
          })
      case .application(let action, let inBackground, let hideWhenRunning, let ifNotRunning):
        ApplicationCommandView(
          $command,
          actionName: action,
          inBackground: inBackground,
          hideWhenRunning: hideWhenRunning,
          ifNotRunning: ifNotRunning,
          onAction: { action in
            let newAction: Action = .application(action: action, workflowId: workflowId, commandId: command.id)
            if newAction.isAction(.run) { handleRun() }
            onAction(newAction)
          })
      case .script:
        ScriptCommandView(
          $command,
          onAction: { action in
            let newAction: Action = .script(action: action, workflowId: workflowId, commandId: command.id)
            onAction(newAction)
          })
      case .keyboard:
        KeyboardCommandView(
          $command,
          onAction: { action in
            let newAction: Action = .keyboard(action: action, workflowId: workflowId, commandId: command.id)
            onAction(newAction)
          })
      case .shortcut:
        ShortcutCommandView(
          $command,
          onAction: { action in
            let newAction: Action = .shortcut(action: action, workflowId: workflowId, commandId: command.id)
            onAction(newAction)
          })
      case .type:
        TypeCommandView(
          $command,
          onAction: { action in
            let newAction: Action = .type(action: action, workflowId: workflowId, commandId: command.id)
            onAction(newAction)
          })
      }
    }
    .overlay(alignment: .bottom, content: {
      GeometryReader { proxy in
        RoundedRectangle(cornerRadius: 3)
          .fill(
            LinearGradient(
              gradient: Gradient(
                stops: [
                  .init(color: Color(.controlAccentColor).opacity(0.5), location: 0.5),
                  .init(color: Color(.controlAccentColor), location: 0.9),
                  .init(color: Color(.controlAccentColor).opacity(0.5), location: 1.0),
                ]),
              startPoint: .leading,
              endPoint: .trailing)
          )
          .frame(width: progressValue == 0 ? 0 : proxy.size.width / progressValue)
          .opacity(progressAlpha == 0 ? 0 : min(proxy.size.width * progressValue / proxy.size.width, 0.4))
      }
      .frame(height: 5)
    })
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

  private func handleRun() {
    let duration = CGFloat(0.5)
    withAnimation(.easeInOut(duration: duration)) {
      progressAlpha = 1.0
      progressValue = 1.0
      Task {
        try await Task.sleep(seconds: duration / 1.25)
        withAnimation {
          progressAlpha = 0.0
        }
        try await Task.sleep(seconds: duration / 1.25)
        progressValue = 0.0
      }
    }
  }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
