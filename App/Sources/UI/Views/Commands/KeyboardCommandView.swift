import Inject
import SwiftUI


struct KeyboardCommandView: View {
  enum Action {
    case editCommand(CommandViewModel.Kind.KeyboardModel)
    case updateName(newName: String)
    case updateKeyboardShortcuts([KeyShortcut])
    case commandAction(CommandContainerAction)
  }

  private let focus: FocusState<AppFocus?>.Binding
  private let iconSize: CGSize
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.KeyboardModel
  private let onAction: (KeyboardCommandView.Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    KeyboardCommandInternalView(
      focus,
      metaData: metaData,
      model: model,
      iconSize: iconSize,
      onAction: onAction
    )
  }
}

struct KeyboardCommandInternalView: View {
  @StateObject private var keyboardSelection = SelectionManager<KeyShortcut>()
  private let metaData: CommandViewModel.MetaData
  @Binding private var model: CommandViewModel.Kind.KeyboardModel
  private let debounce: DebounceManager<String>
  private let onAction: (KeyboardCommandView.Action) -> Void
  private let iconSize: CGSize
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel,
       iconSize: CGSize,
       onAction: @escaping (KeyboardCommandView.Action) -> Void) {
    self.focus = focus
    self.metaData = metaData
    _model = Binding<CommandViewModel.Kind.KeyboardModel>(model)
    self.onAction = onAction
    self.iconSize = iconSize
    self.debounce = DebounceManager(for: .milliseconds(500)) { newName in
      onAction(.updateName(newName: newName))
    }
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { command in
        KeyboardIconView(size: iconSize.width)
          .overlay {
            Image(systemName: "flowchart")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: iconSize.width / 2)
          }
      }, content: { command in
        EditableKeyboardShortcutsView<AppFocus>(
          focus,
          focusBinding: { .detail(.commandShortcut($0)) },
          mode: .externalEdit({
            onAction(.editCommand(model))
          }),
          keyboardShortcuts: $model.keys,
          draggableEnabled: false,
          selectionManager: keyboardSelection,
          onTab: { _ in })
        .font(.caption)
        .roundedContainer(padding: 0, margin: 0)
      },
      subContent: { _ in
        Button {
          onAction(.editCommand(model))
        } label: {
          Text("Edit")
            .font(.caption)
        }
        .buttonStyle(.zen(.init(color: .systemCyan, grayscaleEffect: .constant(true))))
      },
      onAction: { onAction(.commandAction($0)) })
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static let recorderStore = KeyShortcutRecorderStore()
  static let command = DesignTime.rebindingCommand
  static var previews: some View {
    KeyboardCommandView(
      $focus,
      metaData: command.model.meta,
      model: command.kind,
      iconSize: .init(width: 24, height: 24)
    ) { _ in }
      .designTime()
      .environmentObject(recorderStore)
      .frame(maxHeight: 120)
  }
}
