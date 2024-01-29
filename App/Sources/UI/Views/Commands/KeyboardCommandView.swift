import Inject
import SwiftUI

struct KeyboardCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case editCommand(CommandViewModel.Kind.KeyboardModel)
    case updateName(newName: String)
    case updateKeyboardShortcuts([KeyShortcut])
    case commandAction(CommandContainerAction)
  }

  @StateObject var keyboardSelection = SelectionManager<KeyShortcut>()
  @State private var metaData: CommandViewModel.MetaData
  @Binding private var model: CommandViewModel.Kind.KeyboardModel
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void
  private let iconSize: CGSize
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _metaData = .init(initialValue: metaData)
    _model = Binding<CommandViewModel.Kind.KeyboardModel>(model)
    self.onAction = onAction
    self.iconSize = iconSize
    self.debounce = DebounceManager(for: .milliseconds(500)) { newName in
      onAction(.updateName(newName: newName))
    }
  }

  var body: some View {
    CommandContainerView(
      $metaData, 
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
          keyboardShortcuts: $model.keys,
          draggableEnabled: false,
          selectionManager: keyboardSelection,
          onTab: { _ in })
        .font(.caption)
        .onChange(of: model.keys) { newValue in
          onAction(.updateKeyboardShortcuts(newValue))
        }
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
    .enableInjection()
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
