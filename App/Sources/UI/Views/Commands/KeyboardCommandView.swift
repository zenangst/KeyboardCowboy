import Inject
import SwiftUI

struct KeyboardCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateName(newName: String)
    case updateKeyboardShortcuts([KeyShortcut])
    case commandAction(CommandContainerAction)
  }

  @StateObject var keyboardSelection = SelectionManager<KeyShortcut>()
  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.KeyboardModel
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction
    self.debounce = DebounceManager(for: .milliseconds(500)) { newName in
      onAction(.updateName(newName: newName))
    }
  }

  var body: some View {
    CommandContainerView(
      $metaData, icon: { command in
        ZStack {
          Rectangle()
            .fill(Color(.systemGreen))
            .opacity(0.2)
            .cornerRadius(8)
          ZStack {
            RegularKeyIcon(letter: "")
            Image(systemName: "flowchart")
          }
          .scaleEffect(0.8)
        }
      }, content: { command in
        VStack(spacing: 10) {
          HStack(spacing: 0) {
            TextField("", text: $metaData.name)
              .textFieldStyle(.regular(Color(.windowBackgroundColor)))
              .onChange(of: metaData.name, perform: { debounce.send($0) })
              .frame(maxWidth: .infinity)
          }
          EditableKeyboardShortcutsView<AppFocus>(focus,
                                                  focusBinding: { .detail(.commandShortcut($0)) },
                                                  keyboardShortcuts: $model.keys,
                                                  selectionManager: keyboardSelection,
                                                  onTab: { _ in })
          .font(.caption)
          .frame(height: 40)
          .onChange(of: model.keys) { newValue in
            onAction(.updateKeyboardShortcuts(newValue))
          }
          .roundedContainer(padding: 0, margin: 0)
        }
      },
      subContent: { _ in },
      onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static let recorderStore = KeyShortcutRecorderStore()
  static let command = DesignTime.rebindingCommand
  static var previews: some View {
    KeyboardCommandView($focus, metaData: command.model.meta, model: command.kind) { _ in }
      .designTime()
      .environmentObject(recorderStore)
      .frame(maxHeight: 120)
  }
}
