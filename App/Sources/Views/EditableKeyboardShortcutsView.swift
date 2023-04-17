import SwiftUI

struct EditableKeyboardShortcutsView: View {
  enum CurrentState: Hashable {
    case recording
  }
  @Environment(\.controlActiveState) var controlActiveState
  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore
  @Binding var keyboardShortcuts: [KeyShortcut]
  @State var state: CurrentState? = nil
  @State var isGlowing: Bool = false
  @State var replacing: KeyShortcut.ID?
  @State var selectedColor: Color = .accentColor

  private let placeholderId = "keyboard_shortcut_placeholder_id"
  private let animation: Animation = .easeOut(duration: 0.2)
  private let focusManager = EditableFocusManager<KeyShortcut.ID>()
  private let selectionManager = EditableSelectionManager<KeyShortcut>()

  var body: some View {
    ScrollViewReader { proxy in
      HStack {
        ScrollView(.horizontal) {
          content(proxy)
        }
        Spacer()
        addButton(proxy)
      }
      .overlay(overlay(proxy))
    }
    .onChange(of: controlActiveState, perform: { value in
      if value != .key {
        reset()
      }
    })
    .onChange(of: recorderStore.recording, perform: { newValue in
      guard state == .recording, let newValue else { return }
      switch newValue {
      case .valid(let newKeyboardShortcut):
        withAnimation(animation) {
          if let replacing, let index = keyboardShortcuts.firstIndex(where: { $0.id == replacing }) {
            keyboardShortcuts[index] = newKeyboardShortcut
          } else {
            keyboardShortcuts.append(newKeyboardShortcut)
          }
          reset()
        }
      case .cancel:
        reset()
      default:
        break
      }
    })
  }

  private func content(_ proxy: ScrollViewProxy) -> some View {
    EditableStack(
      $keyboardShortcuts,
      configuration: .init(axes: .horizontal, selectedColor: selectedColor),
      focusManager: focusManager,
      selectionManager: selectionManager,
      scrollProxy: proxy,
      onClick: { id, index in
        if replacing == id {
          record()
        }
        replacing = id
      },
      onMove: { from, to in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
          keyboardShortcuts.move(fromOffsets: from, toOffset: to)
        }
      },
      onDelete: { offsets in
        withAnimation(animation) {
          keyboardShortcuts.remove(atOffsets: offsets)
        }
      },
      content: { keyboardShortcut, _ in
        HStack(spacing: 6) {
          ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
            ModifierKeyIcon(
              key: modifier,
              alignment: keyboardShortcut.wrappedValue.lhs
              ? modifier == .shift ? .bottomLeading : .topTrailing
              : modifier == .shift ? .bottomTrailing : .topLeading
            )
            .frame(minWidth: modifier == .command || modifier == .shift ? 44 : 32, minHeight: 32)
            .fixedSize(horizontal: true, vertical: true)
          }
          RegularKeyIcon(letter: keyboardShortcut.wrappedValue.key, width: 32, height: 32)
            .fixedSize(horizontal: true, vertical: true)
        }
        .contextMenu {
          Text(keyboardShortcut.wrappedValue.validationValue)
          Divider()
          Button("Re-record") {
            replacing = keyboardShortcut.id
            record()
          }
          Button("Remove") {
            if let index = keyboardShortcuts.firstIndex(where: { $0.id == keyboardShortcut.id }) {
              _ = withAnimation(animation) {
                keyboardShortcuts.remove(at: index)
              }
            }
          }
        }
        .padding(4)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(Color(.disabledControlTextColor))
            .opacity(0.5)
        )
        .id(keyboardShortcut.id)
      })
    .padding(4)
  }

  @ViewBuilder
  private func overlay(_ proxy: ScrollViewProxy) -> some View {
    if state == .recording {
      RoundedRectangle(cornerRadius: 4)
        .stroke(isGlowing
                ? Color(.systemRed) .opacity(0.5)
                : Color.clear, lineWidth: 1)
        .animation(Animation
          .easeInOut(duration: 1.25)
          .repeatForever(autoreverses: true), value: isGlowing)
    } else if keyboardShortcuts.isEmpty {
      Text("Click to record a keyboard shortcut")
        .allowsTightening(true)
        .font(.footnote)
        .padding([.leading, .vertical], 4)
        .padding(.trailing, 32)
        .onTapGesture(perform: { addButtonAction(proxy) })
    }
  }

  private func addButton(_ proxy: ScrollViewProxy) -> some View {
    Button(action: { addButtonAction(proxy) },
           label: { Image(systemName: "plus").frame(width: 10, height: 10) })
    .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
    .padding(.trailing, 4)
    .disabled(state == .recording)
  }

  private func addButtonAction(_ proxy: ScrollViewProxy) {
    let keyShortcut = KeyShortcut(id: placeholderId, key: "Recording ...", lhs: true)
    focusManager.focus = .focused(keyShortcut.id)
    selectionManager.selections = [keyShortcut.id]
    state = .recording
    recorderStore.mode = .record
    replacing = keyShortcut.id
    keyboardShortcuts.append(keyShortcut)
    withAnimation(animation) {
      isGlowing = true
      selectedColor = Color(.systemRed)
      DispatchQueue.main.async {
        withAnimation(animation) {
          proxy.scrollTo(keyShortcut.id)
        }
      }
    }
  }

  private func record() {
    isGlowing = true
    withAnimation {
      state = .recording
      recorderStore.mode = .record
      selectedColor = Color(.systemRed)
    }
  }

  private func reset() {
    replacing = nil
    state = nil
    isGlowing = false
    selectedColor = Color.accentColor
    if recorderStore.mode != .intercept {
      recorderStore.mode = .intercept
    }
    withAnimation(animation) {
      keyboardShortcuts.removeAll(where: { $0.id == placeholderId })
    }
  }
}
