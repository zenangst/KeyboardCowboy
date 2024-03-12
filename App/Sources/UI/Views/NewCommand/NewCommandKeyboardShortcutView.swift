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
  @State private var keyboardShortcuts: [KeyShortcut]
  @State private var state: CurrentState? = nil
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#keyboard-shortcuts-commands")!
  private let selectionManager: SelectionManager<KeyShortcut> = .init()

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation

    if case .keyboardShortcut(let shortcuts) = payload.wrappedValue {
      _keyboardShortcuts = .init(initialValue: shortcuts)
    } else {
      _keyboardShortcuts = .init(initialValue: [])
    }
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
          mode: .inlineEdit,
          keyboardShortcuts: $keyboardShortcuts,
          draggableEnabled: true,
          selectionManager: selectionManager,
          onTab: { _ in })
        .onChange(of: keyboardShortcuts, perform: { newValue in
          keyboardShortcuts = newValue
        })
        .roundedContainer(padding: 2, margin: 0)
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
    Group {
      NewCommandView(
        workflowId: UUID().uuidString,
        commandId: nil,
        title: "New command",
        selection: .keyboardShortcut,
        payload: .keyboardShortcut([
          .init(key: "M", modifiers: [.function]),
          .init(key: "O"),
          .init(key: "L"),
          .init(key: "L"),
          .init(key: "Y"),
        ]),
        onDismiss: {},
        onSave: { _, _ in })

      NewCommandView(
        workflowId: UUID().uuidString,
        commandId: nil,
        title: "New command",
        selection: .keyboardShortcut,
        payload: .placeholder,
        onDismiss: {},
        onSave: { _, _ in })
    }
    .designTime()
  }
}

