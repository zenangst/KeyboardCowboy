import Bonzai
import Inject
import SwiftUI

struct CommandView: View {
  struct CommandViewPayload {
    let workflowId: DetailViewModel.ID
    let commandId: CommandViewModel.ID
  }

  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var openWindow: WindowOpener

  @Binding private var command: CommandViewModel
  @Environment(\.controlActiveState) private var controlActiveState
  private let publisher: CommandsPublisher
  private let selectionManager: SelectionManager<CommandViewModel>
  private let workflowId: String
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       command: Binding<CommandViewModel>,
       publisher: CommandsPublisher,
       selectionManager: SelectionManager<CommandViewModel>,
       workflowId: String)
  {
    _command = command
    self.focus = focus
    self.publisher = publisher
    self.selectionManager = selectionManager
    self.workflowId = workflowId
  }

  var body: some View {
    CommandResolverView(focus, command: $command, workflowId: workflowId)
      .onChange(of: command.meta.isEnabled, perform: { newValue in
        updater.modifyCommand(withID: command.meta.id, using: transaction) { command in
          command.isEnabled = newValue
        }
      })
      .overlay(BorderedOverlayView(.readonly { selectionManager.selections.contains(command.id) }, cornerRadius: 8))
      .style(.item)
      .compositingGroup()
      .draggable($command.wrappedValue)
      .environmentObject(selectionManager)
      .animation(.none, value: command.meta.isEnabled)
      .grayscale(command.meta.isEnabled ? controlActiveState == .key ? 0 : 0.25 : 0.5)
      .opacity(command.meta.isEnabled ? 1 : 0.5)
      .animation(.easeIn(duration: 0.2), value: command.meta.isEnabled)
      .enableInjection()
  }
}

struct CommandResolverView: View {
  @EnvironmentObject var openWindow: WindowOpener
  @Binding private var command: CommandViewModel
  private let workflowId: DetailViewModel.ID
  private var focus: FocusState<AppFocus?>.Binding
  private let iconSize = CGSize(width: 24, height: 24)

  init(_ focus: FocusState<AppFocus?>.Binding, command: Binding<CommandViewModel>, workflowId: String) {
    _command = command
    self.focus = focus
    self.workflowId = workflowId
  }

  var body: some View {
    switch command.kind {
    case let .application(model): ApplicationCommandView(command.meta, model: model, iconSize: iconSize)
    case let .builtIn(model): BuiltInCommandView(command.meta, model: model, iconSize: iconSize)
    case let .bundled(model): BundledCommandView(command.meta, model: model, iconSize: iconSize)
    case let .inputSource(model): InputSourceCommandView(command.meta, model: model, iconSize: iconSize)
    case let .keyboard(model): KeyboardCommandView(focus, metaData: command.meta, model: model, iconSize: iconSize)
    case let .menuBar(model): MenuBarCommandView(command.meta, model: model, iconSize: iconSize)
    case let .mouse(model): MouseCommandView(command.meta, model: model, iconSize: iconSize)
    case let .open(model): OpenCommandView(command.meta, model: model, iconSize: iconSize)
    case let .script(model): ScriptCommandView(command.meta, model: .constant(model), iconSize: iconSize, onSubmit: {})
    case let .shortcut(model): ShortcutCommandView(command.meta, model: model, iconSize: iconSize)
    case let .systemCommand(model): SystemCommandView(command.meta, model: model, iconSize: iconSize)
    case let .text(textModel): TextCommandView(kind: textModel.kind, metaData: command.meta, iconSize: iconSize)
    case let .uiElement(model): UIElementCommandView(metaData: command.meta, model: Binding<UIElementCommand>(get: { model }, set: { _ in }), iconSize: iconSize)
    case let .windowFocus(model): WindowFocusCommandView(command.meta, model: model, iconSize: iconSize)
    case let .windowManagement(model): WindowManagementCommandView(command.meta, model: model, iconSize: iconSize)
    case let .windowTiling(model): WindowTilingCommandView(command.meta, model: model, iconSize: iconSize)
    }
  }
}
