import SwiftUI

struct CommandView: View {
  enum Action {
    case changeDelay(workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID, newValue: Double?)
    case toggleNotify(workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID, newValue: Bool)
    case toggleEnabled(workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID, newValue: Bool)
    case modify(Kind)
    case run(workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case remove(workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
  }

  enum Kind {
    case application(action: ApplicationCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case keyboard(action: KeyboardCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case open(action: OpenCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case script(action: ScriptCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case shortcut(action: ShortcutCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case type(action: TypeCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case system(action: SystemCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case window(action: WindowManagementCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
  }

  @Environment(\.openWindow) var openWindow
  @Environment(\.controlActiveState) var controlActiveState

  private let workflowId: String
  private let detailPublisher: DetailPublisher
  private let selectionManager: SelectionManager<CommandViewModel>
  private let focusPublisher: FocusPublisher<CommandViewModel>
  @State var isTargeted: Bool = false
  @Binding private var command: CommandViewModel
  private let onCommandAction: (SingleDetailView.Action) -> Void
  private let onAction: (Action) -> Void

  init(_ command: Binding<CommandViewModel>,
       detailPublisher: DetailPublisher,
       focusPublisher: FocusPublisher<CommandViewModel>,
       selectionManager: SelectionManager<CommandViewModel>,
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
      .onChange(of: command.meta.isEnabled, perform: { newValue in
        onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: newValue))
      })
      .background(
        FocusView(focusPublisher, element: $command,
                  isTargeted: $isTargeted,
                  selectionManager: selectionManager, cornerRadius: 8,
                  style: .focusRing)
      )
      .background(
        Color(.windowBackgroundColor).cornerRadius(8)
      )
      .compositingGroup()
      .draggable($command.wrappedValue.draggablePayload(prefix: "WC|", selections: selectionManager.selections))
      .dropDestination(for: DropItem.self, action: { items, location in
        var urls = [URL]()
        for item in items {
          switch item {
          case .text(let item):
            if !item.hasPrefix("WC|"), let url = URL(string: item) {
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
      .animation(.none, value: command.meta.isEnabled)
      .grayscale(command.meta.isEnabled ? controlActiveState == .key ? 0 : 0.25 : 0.5)
      .opacity(command.meta.isEnabled ? 1 : 0.5)
      .animation(.easeIn(duration: 0.2), value: command.meta.isEnabled)
  }
}

struct CommandResolverView: View {
  @Environment(\.openWindow) var openWindow
  @Binding private var command: CommandViewModel
  private let workflowId: DetailViewModel.ID
  private let onAction: (CommandView.Action) -> Void

  init(_ command: Binding<CommandViewModel>,
       workflowId: String,
       onAction: @escaping (CommandView.Action) -> Void) {
    _command = command
    self.workflowId = workflowId
    self.onAction = onAction
  }

  var body: some View {
    switch command.kind {
    case .plain:
      UnknownView(command: .constant(command))
    case .menuBar(let model):
      MenuBarCommandView($command.meta, model: model) { action in
        switch action {
        case .editCommand(let command):
          openWindow(value: NewCommandWindow.Context.editCommand(workflowId: workflowId, commandId: command.id))
          break
        case .commandAction(let action):
          handleCommandContainerAction(action)
        }
      }
    case .open(let model):
      OpenCommandView(command.meta, model: model){ action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.open(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
    case .application(let model):
      ApplicationCommandView(command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.application(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
    case .script(let model):
      ScriptCommandView(command.meta, model: model) { action in
          switch action {
          case .edit:
            return
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.script(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
    case .keyboard(let model):
      KeyboardCommandView(command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.keyboard(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
    case .shortcut(let model):
      ShortcutCommandView(command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.shortcut(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
    case .type(let model):
      TypeCommandView($command.meta, model: Binding(get: { model }, set: { _ in })) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.type(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
    case .systemCommand(let model):
      SystemCommandView($command.meta, model: model) { action in
        switch action {
        case .commandAction(let action):
          handleCommandContainerAction(action)
        default:
          onAction(.modify(.system(action: action, workflowId: workflowId, commandId: command.id)))
        }
      }
    case .windowManagement(let model):
      WindowManagementCommandView($command.meta, model: model) { action in
        switch action {
        case .onUpdate:
          onAction(.modify(.window(action: action, workflowId: workflowId, commandId: command.id)))
        case .commandAction(let commandContainerAction):
          handleCommandContainerAction(commandContainerAction)
        }
      }
    }
  }

  func handleCommandContainerAction(_ action: CommandContainerAction) {
    switch action {
    case .run:
      onAction(.run(workflowId: workflowId, commandId: command.id))
    case .delete:
      onAction(.remove(workflowId: workflowId, commandId: command.id))
    case .toggleIsEnabled(let isEnabled):
      onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: isEnabled))
    case .toggleNotify(let newValue):
      onAction(.toggleNotify(workflowId: workflowId, commandId: command.id, newValue: newValue))
    case .changeDelay(let newValue):
      onAction(.changeDelay(workflowId: workflowId, commandId: command.id, newValue: newValue))
    }
  }
}

