import Bonzai
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
    case builtIn(action: BuiltInCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case keyboard(action: KeyboardCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case mouse(action: MouseCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case open(action: OpenCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case script(action: ScriptCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case shortcut(action: ShortcutCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case type(action: TypeCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case system(action: SystemCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
    case window(action: WindowManagementCommandView.Action, workflowId: DetailViewModel.ID, commandId: CommandViewModel.ID)
  }

  @Binding private var command: CommandViewModel
  @Environment(\.controlActiveState) private var controlActiveState
  @Environment(\.openWindow) private var openWindow
  @State private var isTargeted: Bool = false
  private let publisher: CommandsPublisher
  private let selectionManager: SelectionManager<CommandViewModel>
  private let workflowId: String
  private let onCommandAction: (SingleDetailView.Action) -> Void
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       command: Binding<CommandViewModel>,
       publisher: CommandsPublisher,
       selectionManager: SelectionManager<CommandViewModel>,
       workflowId: String,
       onCommandAction: @escaping (SingleDetailView.Action) -> Void,
       onAction: @escaping (Action) -> Void) {
    _command = command
    self.focus = focus
    self.publisher = publisher
    self.selectionManager = selectionManager
    self.workflowId = workflowId
    self.onCommandAction = onCommandAction
    self.onAction = onAction
  }

  var body: some View {
    CommandResolverView(focus, command: $command, workflowId: workflowId, onAction: onAction)
      .onChange(of: command.meta.isEnabled, perform: { newValue in
        onAction(.toggleEnabled(workflowId: workflowId, commandId: command.id, newValue: newValue))
      })
      .overlay(BorderedOverlayView(cornerRadius: 8))
      .background(
        Color(.windowBackgroundColor).cornerRadius(8)
          .drawingGroup()
      )
      .compositingGroup()
      .draggable($command.wrappedValue.draggablePayload(prefix: "WC|", selections: selectionManager.selections))
      .dropDestination(DropItem.self, color: .accentColor) { items, location in
        var urls = [URL]()
        for item in items {
          switch item {
          case .text(let item):
            // Don't accept dropping keyboard shortcuts.
            if item.hasPrefix("WKS|") { return false }

            if !item.hasPrefix("WC|"),
               let url = URL(string: item) {
              urls.append(url)
              continue
            }
            guard let payload = item.draggablePayload(prefix: "WC|"),
                  let (from, destination) = publisher.data.commands.moveOffsets(for: $command.wrappedValue,
                                                                                with: payload) else {
              return false
            }
            withAnimation(WorkflowCommandListView.animation) {
              publisher.data.commands.move(fromOffsets: IndexSet(from), toOffset: destination)
            }
            onCommandAction(.moveCommand(workflowId: workflowId, indexSet: from, toOffset: destination))
            return true
          case .url(let url):
            urls.append(url)
          case .none:
            return false
          }
        }

        if !urls.isEmpty {
          onCommandAction(.dropUrls(workflowId: workflowId, urls: urls))
          return true
        }
        return false
      }
      .environmentObject(selectionManager)
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
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       command: Binding<CommandViewModel>,
       workflowId: String,
       onAction: @escaping (CommandView.Action) -> Void) {
    _command = command
    self.focus = focus
    self.workflowId = workflowId
    self.onAction = onAction
  }

  var body: some View {
    switch command.kind {
    case .plain:
      UnknownView(command: .constant(command))
    case .builtIn(let model):
      BuiltInCommandView(command.meta, model: model) { action in
        switch action {
        case .update(let newCommand):
          onAction(.modify(.builtIn(action: .update(newCommand), workflowId: workflowId, commandId: command.id)))
        case .commandAction(let action):
          handleCommandContainerAction(action)
        }
      }
    case .menuBar(let model):
      MenuBarCommandView(command.meta, model: model) { action in
        switch action {
        case .editCommand(let command):
          openWindow(value: NewCommandWindow.Context.editCommand(workflowId: workflowId, commandId: command.id))
          break
        case .commandAction(let action):
          handleCommandContainerAction(action)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(height: 80)
    case .mouse(let model):
      MouseCommandView(command.meta, model: model, onAction: { action in
        switch action {
        case .update:
          onAction(.modify(.mouse(action: action, workflowId: workflowId, commandId: command.id)))
        case .commandAction(let action):
          handleCommandContainerAction(action)
        }
      })
    case .open(let model):
      OpenCommandView(command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.open(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
      .fixedSize(horizontal: false, vertical: true)
      .frame(height: 80)
    case .application(let model):
      ApplicationCommandView(command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.application(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
      .fixedSize(horizontal: false, vertical: true)
      .frame(height: 80)
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
      KeyboardCommandView(focus, metaData: command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.keyboard(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
      .fixedSize(horizontal: false, vertical: true)
      .frame(height: 124)
    case .shortcut(let model):
      ShortcutCommandView(command.meta, model: model) { action in
          switch action {
          case .commandAction(let action):
            handleCommandContainerAction(action)
          default:
            onAction(.modify(.shortcut(action: action, workflowId: workflowId, commandId: command.id)))
          }
        }
      .fixedSize(horizontal: false, vertical: true)
      .frame(height: 110)
    case .text(let textModel):
      TextCommandView(kind: textModel.kind, metaData: command.meta, onTypeAction: { action in
        switch action {
        case .commandAction(let action):
          handleCommandContainerAction(action)
        default:
          onAction(.modify(.type(action: action, workflowId: workflowId, commandId: command.id)))
        }
      })
    case .systemCommand(let model):
      SystemCommandView(command.meta, model: model) { action in
        switch action {
        case .commandAction(let action):
          handleCommandContainerAction(action)
        default:
          onAction(.modify(.system(action: action, workflowId: workflowId, commandId: command.id)))
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(height: 80)
    case .windowManagement(let model):
      WindowManagementCommandView(command.meta, model: model) { action in
        switch action {
        case .onUpdate:
          onAction(.modify(.window(action: action, workflowId: workflowId, commandId: command.id)))
        case .commandAction(let commandContainerAction):
          handleCommandContainerAction(commandContainerAction)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(minHeight: 80, maxHeight: 160)
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

