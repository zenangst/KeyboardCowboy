import Bonzai
import SwiftUI

struct CommandView: View {
  struct CommandViewPayload {
    let workflowId: DetailViewModel.ID
    let commandId: CommandViewModel.ID
  }

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
       workflowId: String) {
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
      .style(.item)
      .overlay(BorderedOverlayView(.readonly { selectionManager.selections.contains(command.id) }, cornerRadius: 6))
      .compositingGroup()
      .draggable($command.wrappedValue)
      .environmentObject(selectionManager)
      .animation(.none, value: command.meta.isEnabled)
      .grayscale(command.meta.isEnabled ? controlActiveState == .key ? 0 : 0.25 : 0.5)
      .opacity(command.meta.isEnabled ? 1 : 0.5)
      .animation(.easeIn(duration: 0.2), value: command.meta.isEnabled)
  }
}

struct CommandResolverView: View {
  @EnvironmentObject var openWindow: WindowOpener
  @Binding private var command: CommandViewModel
  private let workflowId: DetailViewModel.ID
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding, command: Binding<CommandViewModel>, workflowId: String) {
    _command = command
    self.focus = focus
    self.workflowId = workflowId
  }

  var body: some View {
    let iconSize = CGSize(width: 24, height: 24)
    switch command.kind {
    case .application(let model):      ApplicationCommandView(command.meta, model: model, iconSize: iconSize)
                                         .fixedSize(horizontal: false, vertical: true)
    case .builtIn(let model):          BuiltInCommandView(command.meta, model: model, iconSize: iconSize)
    case .bundled(let model):          BundledCommandView(command.meta, model: model, iconSize: iconSize)
    case .menuBar(let model):          MenuBarCommandView(command.meta, model: model, iconSize: iconSize)
    case .mouse(let model):            MouseCommandView(command.meta, model: model, iconSize: iconSize)
    case .open(let model):             OpenCommandView(command.meta, model: model, iconSize: iconSize)
    case .script(let model):           ScriptCommandView(command.meta, model: .constant(model), iconSize: iconSize, onSubmit: {})
    case .keyboard(let model):         KeyboardCommandView(focus, metaData: command.meta, model: model, iconSize: iconSize)
    case .shortcut(let model):         ShortcutCommandView(command.meta, model: model, iconSize: iconSize)
    case .text(let textModel):         TextCommandView(kind: textModel.kind, metaData: command.meta, iconSize: iconSize)
    case .systemCommand(let model):    SystemCommandView(command.meta, model: model, iconSize: iconSize)
    case .uiElement(let model):        UIElementCommandView(metaData: command.meta, model: model, iconSize: iconSize)
    case .windowManagement(let model): WindowManagementCommandView(command.meta, model: model, iconSize: iconSize)
    }
  }
}
