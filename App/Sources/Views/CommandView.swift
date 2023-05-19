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
  private var detailPublisher: DetailPublisher
  private var selectionManager: SelectionManager<DetailViewModel.CommandViewModel>
  private var focusPublisher: FocusPublisher<DetailViewModel.CommandViewModel>
  @State var isTargeted: Bool = false
  @Binding private var command: DetailViewModel.CommandViewModel
  private let onCommandAction: (SingleDetailView.Action) -> Void
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       detailPublisher: DetailPublisher,
       focusPublisher: FocusPublisher<DetailViewModel.CommandViewModel>,
       selectionManager: SelectionManager<DetailViewModel.CommandViewModel>,
       workflowId: String,
       onCommandAction: @escaping (SingleDetailView.Action) -> Void,
       onAction: @escaping (Action) -> Void) {
    _command = command
    self.detailPublisher = detailPublisher
    self.selectionManager = selectionManager
    self.focusPublisher = focusPublisher
    self.workflowId = workflowId
    self.onCommandAction = onCommandAction
    self.onAction = onAction
  }

  var body: some View {
    CommandResolverView($command, workflowId: workflowId, onAction: onAction)
      .onChange(of: command.isEnabled, perform: { newValue in
        onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: newValue))
      })
      .background(
        FocusView(focusPublisher, element: $command,
                  isTargeted: $isTargeted,
                  selectionManager: selectionManager, cornerRadius: 8,
                  style: .focusRing)
      )
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
      .draggable($command.wrappedValue.draggablePayload(prefix: "WC|", selections: selectionManager.selections))
      .dropDestination(for: DropItem.self, action: { items, location in
        var urls = [URL]()
        for item in items {
          switch item {
          case .text(let item):
            if let url = URL(string: item) {
              urls.append(url)
              continue
            }
            guard let payload = item.draggablePayload(prefix: "WC|"),
                  let (from, destination) = detailPublisher.data.commands.moveOffsets(for: $command.wrappedValue,
                                                                                      with: payload) else {
              return false
            }
            withAnimation(WorkflowCommandListView.animation) {
              detailPublisher.data.commands.move(fromOffsets: IndexSet(from), toOffset: destination)
            }
            onCommandAction(.moveCommand(workflowId: detailPublisher.data.id, indexSet: from, toOffset: destination))
            return true
          case .url(let url):
            urls.append(url)
          case .none:
            return false
          }
        }

        if !urls.isEmpty {
          onCommandAction(.dropUrls(workflowId: detailPublisher.data.id, urls: urls))
          return true
        }
        return false
      }, isTargeted: { newValue in
        isTargeted = newValue
      })
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
