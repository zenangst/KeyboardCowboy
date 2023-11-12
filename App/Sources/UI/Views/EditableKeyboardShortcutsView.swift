import Bonzai
import SwiftUI

struct EditableKeyboardShortcutsView<T: Hashable>: View {
  enum CurrentState: Hashable {
    case recording
  }

  @FocusState private var focus: T?
  @Environment(\.controlActiveState) private var controlActiveState
  @EnvironmentObject private var recorderStore: KeyShortcutRecorderStore
  @Binding private var keyboardShortcuts: [KeyShortcut]
  @State private var state: CurrentState? = nil
  @State private var isGlowing: Bool = false
  @State private var replacing: KeyShortcut.ID?
  @State private var selectedColor: Color = .accentColor
  private let animation: Animation = .easeOut(duration: 0.2)
  private let focusBinding: (KeyShortcut.ID) -> T
  private let onTab: (Bool) -> Void
  private let placeholderId = "keyboard_shortcut_placeholder_id"
  private let selectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<T?>,
       focusBinding: @escaping (KeyShortcut.ID) -> T,
       keyboardShortcuts: Binding<[KeyShortcut]>,
       state: CurrentState? = nil,
       selectionManager: SelectionManager<KeyShortcut>,
       onTab: @escaping (Bool) -> Void) {
    _focus = focus
    _keyboardShortcuts = keyboardShortcuts
    _state = .init(initialValue: state)
    self.focusBinding = focusBinding
    self.onTab = onTab
    self.selectionManager = selectionManager
  }

  var body: some View {
    ScrollViewReader { proxy in
      HStack {
        ScrollView(.horizontal) {
          LazyHStack {
            ForEach($keyboardShortcuts) { keyboardShortcut in
              EditableKeyboardShortcutsItemView(
                keyboardShortcut: keyboardShortcut,
                keyboardShortcuts: $keyboardShortcuts,
                selectionManager: selectionManager
              )
              .contentShape(Rectangle())
              .contextMenu {
                Text(keyboardShortcut.wrappedValue.validationValue)
                Divider()
                Button("Change Keyboard Shortcut") { rerecord(keyboardShortcut.id) }
                Button("Remove") {
                  if let index = keyboardShortcuts.firstIndex(where: { $0.id == keyboardShortcut.id }) {
                    _ = withAnimation(animation) {
                      keyboardShortcuts.remove(at: index)
                    }
                  }
                }
              }
              .focusable($focus, as: focusBinding(keyboardShortcut.wrappedValue.id), onFocus: {
                selectionManager.handleOnTap(keyboardShortcuts, element: keyboardShortcut.wrappedValue)
              })
              .simultaneousGesture(
                TapGesture(count: 2)
                  .onEnded { _ in rerecord(keyboardShortcut.id) }
              )
              .id(keyboardShortcut.id)
            }
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              onTab(true)
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
              onTab(false)
            })
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              selectionManager.publish(Set(keyboardShortcuts.map(\.id)))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = selectionManager.handle(
                direction,
                keyboardShortcuts,
                proxy: proxy,
                vertical: false) {
                focus = focusBinding(elementID)
              }
            })
            .onDeleteCommand {
              let fromOffsets = IndexSet(keyboardShortcuts.enumerated()
                .filter { selectionManager.selections.contains($0.element.id) }
                .map { $0.offset })

              withAnimation(animation) {
                keyboardShortcuts.remove(atOffsets: fromOffsets)
              }
            }
          }
          .padding(4)
        }
        Spacer()
        Button(action: { addButtonAction(proxy) },
               label: {
          Image(systemName: "plus.diamond")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 14, maxHeight: 14)
            .padding(1)
        })
        .buttonStyle(.calm(color: .systemGreen, padding: .medium))
        .opacity(!keyboardShortcuts.isEmpty ? 1 : 0)
        .padding(.trailing, 4)
        .disabled(state == .recording)
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

  private func rerecord(_ id: KeyShortcut.ID) {
    replacing = id
    record()
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
      Button(action: {
        addButtonAction(proxy)
      }, label: {
        HStack(spacing: 8) {
          Spacer()
          Text("Click to record a keyboard shortcut")
            .lineLimit(1)
            .padding(6)
            .frame(maxWidth: .infinity)
          Spacer()
          Divider()
            .opacity(0.5)
          Image(systemName: "plus.diamond")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .padding(.trailing, 4)
        }
      })
      .buttonStyle(.positive)
      .fixedSize(horizontal: false, vertical: true)
      .padding(6)
    }
  }

  private func addButtonAction(_ proxy: ScrollViewProxy) {
    let keyShortcut = KeyShortcut(id: placeholderId, key: "Recording ...", lhs: true)
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

struct EditableKeyboardShortcutsView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    EditableKeyboardShortcutsView(
      _focus,
      focusBinding: { .detail(.keyboardShortcut($0)) },
      keyboardShortcuts: .constant([ ]),
      state: .recording,
      selectionManager: SelectionManager<KeyShortcut>.init(),
      onTab: { _ in })
    .designTime()
    .padding()
  }
}
