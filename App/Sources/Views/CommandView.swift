import SwiftUI

struct CommandView: View {
  enum Action {
    case toggleEnabled(workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID, newValue: Bool)
    case modify(Kind)
    case run(workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case remove(workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
  }

  enum Kind {
    case application(action: ApplicationCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case keyboard(action: KeyboardCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case open(action: OpenCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case script(action: ScriptCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case shortcut(action: ShortcutCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case type(action: TypeCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
    case system(action: SystemCommandView.Action, workflowId: DetailViewModel.ID, commandId: DetailViewModel.CommandViewModel.ID)
  }

  @Environment(\.controlActiveState) var controlActiveState

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
    CommandResolverView($command, workflowId: workflowId, onAction: onAction)
      .onChange(of: command.isEnabled, perform: { newValue in
        onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: newValue))
      })
      .background(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.1, of: .white.withAlphaComponent(0.1))!), location: 0.0),
          .init(color: Color(.windowBackgroundColor), location: 0.01),
          .init(color: Color(.windowBackgroundColor), location: 0.99),
          .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.2, of: .black.withAlphaComponent(0.1))!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
        .cornerRadius(8)
      )
      .compositingGroup()
      .animation(.none, value: command.isEnabled)
      .grayscale(command.isEnabled ? controlActiveState == .key ? 0 : 0.25 : 0.5)
      .opacity(command.isEnabled ? 1 : 0.5)
      .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1),
              radius: command.isEnabled ? 4 : 2,
              y: command.isEnabled ? 2 : 0)
      .animation(.easeIn(duration: 0.2), value: command.isEnabled)
  }
}

struct CommandResolverView: View {
  @Binding private var command: DetailViewModel.CommandViewModel
  private let workflowId: DetailViewModel.ID
  private let onAction: (CommandView.Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       workflowId: String,
       onAction: @escaping (CommandView.Action) -> Void) {
    _command = command
    self.workflowId = workflowId
    self.onAction = onAction
  }

  var body: some View {
    Group {
      switch command.kind {
      case .plain:
        UnknownView(command: .constant(command))
      case .open:
        OpenCommandView(
          $command,
          onAction: { action in
            switch action {
            case .commandAction(let action):
              switch action {
              case .run:
                onAction(.run(workflowId: workflowId, commandId: command.id))
              case .delete:
                onAction(.remove(workflowId: workflowId, commandId: command.id))
              case .toggleIsEnabled(let isEnabled):
                onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
              }
            default:
              onAction(.modify(.open(action: action, workflowId: workflowId, commandId: command.id)))
            }
          })
      case .application(let action, let inBackground, let hideWhenRunning, let ifNotRunning):
        ApplicationCommandView(
          command,
          actionName: action,
          notify: command.notify,
          inBackground: inBackground,
          hideWhenRunning: hideWhenRunning,
          ifNotRunning: ifNotRunning,
          onAction: { action in
            switch action {
            case .commandAction(let action):
              switch action {
              case .run:
                onAction(.run(workflowId: workflowId, commandId: command.id))
              case .delete:
                onAction(.remove(workflowId: workflowId, commandId: command.id))
              case .toggleIsEnabled(let isEnabled):
                onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
              }
            default:
              onAction(.modify(.application(action: action, workflowId: workflowId, commandId: command.id)))
            }
          })
      case .script:
        ScriptCommandView(
          command,
          onAction: { action in
            switch action {
            case .edit:
              return
            case .commandAction(let action):
              switch action {
              case .run:
                onAction(.run(workflowId: workflowId, commandId: command.id))
              case .delete:
                onAction(.remove(workflowId: workflowId, commandId: command.id))
              case .toggleIsEnabled(let isEnabled):
                onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
              }
            default:
              onAction(.modify(.script(action: action, workflowId: workflowId, commandId: command.id)))
            }
          })
      case .keyboard:
        KeyboardCommandView(
          command,
          notify: command.notify,
          onAction: { action in
            switch action {
            case .commandAction(let action):
              switch action {
              case .run:
                onAction(.run(workflowId: workflowId, commandId: command.id))
              case .delete:
                onAction(.remove(workflowId: workflowId, commandId: command.id))
              case .toggleIsEnabled(let isEnabled):
                onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
              }
            default:
              onAction(.modify(.keyboard(action: action, workflowId: workflowId, commandId: command.id)))
            }
          })
      case .shortcut:
        ShortcutCommandView(
          command,
          onAction: { action in
            switch action {
            case .commandAction(let action):
              switch action {
              case .run:
                onAction(.run(workflowId: workflowId, commandId: command.id))
              case .delete:
                onAction(.remove(workflowId: workflowId, commandId: command.id))
              case .toggleIsEnabled(let isEnabled):
                onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
              }
            default:
              onAction(.modify(.shortcut(action: action, workflowId: workflowId, commandId: command.id)))
            }
          })
      case .type:
        TypeCommandView(
          command,
          onAction: { action in
            switch action {
            case .commandAction(let action):
              switch action {
              case .run:
                onAction(.run(workflowId: workflowId, commandId: command.id))
              case .delete:
                onAction(.remove(workflowId: workflowId, commandId: command.id))
              case .toggleIsEnabled(let isEnabled):
                onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
              }
            default:
              onAction(.modify(.type(action: action, workflowId: workflowId, commandId: command.id)))
            }
          })
      case .systemCommand(let kind):
        SystemCommandView(command, kind: kind) { action in
          switch action {
          case .commandAction(let action):
            switch action {
            case .run:
              onAction(.run(workflowId: workflowId, commandId: command.id))
            case .delete:
              onAction(.remove(workflowId: workflowId, commandId: command.id))
            case .toggleIsEnabled(let isEnabled):
              onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
            }
          default:
            onAction(.modify(.system(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
      }
    }
    .id(command.id)
  }
}

extension Task where Success == Never, Failure == Never {
  static func sleep(seconds: Double) async throws {
    let duration = UInt64(seconds * 1_000_000_000)
    try await Task.sleep(nanoseconds: duration)
  }
}
