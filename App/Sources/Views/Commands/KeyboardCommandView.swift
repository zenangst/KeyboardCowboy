import SwiftUI

struct KeyboardCommandView: View {
  enum Action {
    case toggleNotify(newValue: Bool)
    case updateName(newName: String)
    case updateKeyboardShortcuts([KeyShortcut])
    case commandAction(CommandContainerAction)
  }

  @State private var command: DetailViewModel.CommandViewModel
  @State private var notify: Bool
  @State private var name: String
  @State private var keyboardShortcuts: [KeyShortcut]
  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       notify: Bool,
       onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)
    self.onAction = onAction
    self.notify = .init(notify)
    if case .keyboard(let keyboardShortcuts) = command.kind {
      _keyboardShortcuts = .init(initialValue: keyboardShortcuts)
    } else {
      _keyboardShortcuts = .init(initialValue: [])
    }
  }

  var body: some View {
    CommandContainerView(
      $command, icon: { command in
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
            TextField("", text: $name)
              .textFieldStyle(AppTextFieldStyle())
              .onChange(of: name, perform: {
                onAction(.updateName(newName: $0))
              })
              .frame(maxWidth: .infinity)
          }
          EditableKeyboardShortcutsView($keyboardShortcuts,
                                        selectionManager: .init(),
                                        onTab: { _ in })
            .onChange(of: keyboardShortcuts) { newValue in
              onAction(.updateKeyboardShortcuts(newValue))
            }
            .padding(.horizontal, 2)
            .background(Color(.textBackgroundColor).opacity(0.65))
            .cornerRadius(4)
        }
      },
      subContent: { command in
        Toggle("Notify", isOn: $notify)
          .onChange(of: notify) { newValue in
            onAction(.toggleNotify(newValue: newValue))
          }
          .lineLimit(1)
          .allowsTightening(true)
          .truncationMode(.tail)
          .font(.caption)
      },
      onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  static let recorderStore = KeyShortcutRecorderStore()
  static var previews: some View {
    KeyboardCommandView(DesignTime.rebindingCommand, notify: false, onAction: { _ in })
      .environmentObject(recorderStore)
      .frame(maxHeight: 120)
  }
}
