import Bonzai
import Inject
import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  @ObserveInjection var inject
  enum CurrentState: Hashable {
    case recording
  }
  enum Focus: Hashable {
    case keyboardShortcut(KeyShortcut.ID)
  }
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation
  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore
  @FocusState private var focus: Focus?
  @State private var isGlowing: Bool = false
  @State private var keyboardShortcuts = [KeyShortcut]()
  @State private var state: CurrentState? = nil
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#keyboard-shortcuts-commands")!

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Keyboard Shortcut:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
        .buttonStyle(.calm(color: .systemYellow, padding: .small))
      }
      HStack {
        KeyboardIconView("fn", size: 32)
        EditableKeyboardShortcutsView<Focus>(
          $focus,
          focusBinding: { .keyboardShortcut($0) },
          keyboardShortcuts: $keyboardShortcuts,
          selectionManager: .init(),
          onTab: { _ in })
        .overlay(NewCommandValidationView($validation))
        .frame(minHeight: 48, maxHeight: 48)
      }
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
    .enableInjection()
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

