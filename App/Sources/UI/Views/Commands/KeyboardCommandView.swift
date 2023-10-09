import SwiftUI

struct KeyboardCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateKeyboardShortcuts([KeyShortcut])
    case commandAction(CommandContainerAction)
  }

  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.KeyboardModel
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.KeyboardModel,
       onAction: @escaping (Action) -> Void) {
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
        VStack {
          HStack(spacing: 0) {
            TextField("", text: $metaData.name)
              .textFieldStyle(.regular)
              .onChange(of: metaData.name, perform: { debounce.send($0) })
              .frame(maxWidth: .infinity)
          }
          EditableKeyboardShortcutsView($model.keys,
                                        selectionManager: .init(),
                                        onTab: { _ in })
          .font(.caption)
          .frame(height: 40)
          .onChange(of: model.keys) { newValue in
            onAction(.updateKeyboardShortcuts(newValue))
          }
          .padding(.vertical, 4)
          .background(Color(.textBackgroundColor).opacity(0.65).cornerRadius(4))
        }
      },
      subContent: { _ in },
      onAction: { onAction(.commandAction($0)) })
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  static let recorderStore = KeyShortcutRecorderStore()
  static let command = DesignTime.rebindingCommand
  static var previews: some View {
    KeyboardCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
      .environmentObject(recorderStore)
      .frame(maxHeight: 120)
  }
}
