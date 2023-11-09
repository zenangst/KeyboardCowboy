import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  enum CurrentState: Hashable {
    case recording
  }
  enum Focus: Hashable {
    case keyboardShortcut(KeyShortcut.ID)
  }
  @FocusState var focus: Focus?
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#keyboard-shortcuts-commands")!
  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore

  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State var keyboardShortcuts = [KeyShortcut]()
  @State var isGlowing: Bool = false
  @State var state: CurrentState? = nil

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Label(title: { Text("Keyboard Shortcut:") }, icon: { EmptyView() })
          .labelStyle(HeaderLabelStyle())
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
        .buttonStyle(.calm(color: .systemYellow, padding: .small))
      }

      EditableKeyboardShortcutsView<Focus>(
        $focus,
        focusBinding: { .keyboardShortcut($0) },
        keyboardShortcuts: $keyboardShortcuts,
        selectionManager: .init(),
        onTab: { _ in })
        .overlay(NewCommandValidationView($validation))
        .frame(minHeight: 48, maxHeight: 48)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(.textBackgroundColor).opacity(0.25))
        )
    }
    .onChange(of: keyboardShortcuts, perform: { newValue in
      validation = updateAndValidatePayload()
    })
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      validation = updateAndValidatePayload()
    })
    .onAppear {
      validation = .unknown
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    if keyboardShortcuts.isEmpty {
      payload = .keyboardShortcut([])
      return .invalid(reason: "You need to add at least one keyboard shortcut")
    }

    payload = .keyboardShortcut(keyboardShortcuts)

    return .valid
  }
}

struct NewCommandKeyboardShortcutView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .keyboardShortcut,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}

