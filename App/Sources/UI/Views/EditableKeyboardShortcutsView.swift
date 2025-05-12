import Bonzai
import Inject
import SwiftUI

extension AnyTransition {
  static var keyboardTransition: AnyTransition {
    .asymmetric(
      insertion:
          .scale(scale: 0.1, anchor: .bottom)
          .combined(with: .move(edge: .bottom))
          .combined(with: .opacity)
      ,
      removal:
          .scale.combined(with: .opacity)
    )
  }
}


struct EditableKeyboardShortcutsView<T: Hashable>: View {
  enum CurrentState: Hashable {
    case recording
  }

  enum Mode {
    case inlineEdit
    case externalEdit(_ then: () -> Void)

    var features: Set<EditableKeyboardShortcutsItemView.Feature> {
      switch self {
      case .inlineEdit: [.remove, .record]
      case .externalEdit: []
      }
    }
  }

  @ObserveInjection var inject
  private var focus: FocusState<T?>.Binding
  @Environment(\.controlActiveState) private var controlActiveState
  @EnvironmentObject private var recorderStore: KeyShortcutRecorderStore
  @Binding private var keyboardShortcuts: [KeyShortcut]
  @State private var state: CurrentState? = nil
  @State private var isGlowing: Bool = false
  @State private var replacing: KeyShortcut.ID?
  @State private var selectedColor: Color = .accentColor
  private let animation: Animation = .easeOut(duration: 0.2)
  private let recordOnAppearIfEmpty: Bool
  private let draggableEnabled: Bool
  private let focusBinding: (KeyShortcut.ID) -> T
  private let mode: Mode
  private let onTab: (Bool) -> Void
  private let placeholderId = "keyboard_shortcut_placeholder_id"
  private let selectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<T?>.Binding,
       focusBinding: @escaping (KeyShortcut.ID) -> T,
       mode: Mode,
       keyboardShortcuts: Binding<[KeyShortcut]>,
       draggableEnabled: Bool,
       state: CurrentState? = nil,
       selectionManager: SelectionManager<KeyShortcut>,
       recordOnAppearIfEmpty: Bool = false,
       onTab: @escaping (Bool) -> Void) {
    self.focus = focus
    self.mode = mode
    self.draggableEnabled = draggableEnabled
    _keyboardShortcuts = keyboardShortcuts
    _state = .init(initialValue: state)
    self.focusBinding = focusBinding
    self.onTab = onTab
    self.selectionManager = selectionManager
    self.recordOnAppearIfEmpty = recordOnAppearIfEmpty
  }

  var body: some View {
    ScrollViewReader { proxy in
      HStack {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 8) {
            ForEach($keyboardShortcuts) { keyboardShortcut in
              EditableKeyboardShortcutsItemView(
                keyboardShortcut: keyboardShortcut,
                keyboardShortcuts: $keyboardShortcuts,
                features: mode.features,
                selectionManager: selectionManager,
                onDelete: { keyboardShortcut in
                  guard let index = keyboardShortcuts.firstIndex(of: keyboardShortcut) else { return }

                  _ = withAnimation(animation) {
                    keyboardShortcuts.remove(at: index)
                  }
                }
              )
              .modifier(DraggableToggle(isEnabled: draggableEnabled, model: keyboardShortcut.wrappedValue))
              .contentShape(Rectangle())
              .dropDestination(KeyShortcut.self, alignment: .horizontal, color: .accentColor, onDrop: { items, location in
                let ids: [KeyShortcut.ID] = if selectionManager.selections.isEmpty {
                  items.map(\.id)
                } else {
                  Array(selectionManager.selections)
                }

                guard let (from, destination) = keyboardShortcuts.moveOffsets(for: keyboardShortcut.wrappedValue, with: ids) else {
                  return false
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                  keyboardShortcuts.move(fromOffsets: IndexSet(from), toOffset: destination)
                }

                return true
              })
              .contextMenu {
                Group {
                  Text(keyboardShortcut.wrappedValue.validationValue)
                  Divider()
                  Button("Change Keyboard Shortcut") { handleEdit(keyboardShortcut.id) }
                  Button("Remove") {
                    if let index = keyboardShortcuts.firstIndex(where: { $0.id == keyboardShortcut.id }) {
                      _ = withAnimation(animation) {
                        keyboardShortcuts.remove(at: index)
                      }
                    }
                  }
                }
                .opacity(mode.features.contains(.record) ? 1 : 0)
              }
              .focusable(focus, as: focusBinding(keyboardShortcut.wrappedValue.id), onFocus: {
                selectionManager.handleOnTap(keyboardShortcuts, element: keyboardShortcut.wrappedValue)
              })
              .simultaneousGesture(
                TapGesture(count: 2)
                  .onEnded { _ in handleEdit(keyboardShortcut.id) }
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
                focus.wrappedValue = focusBinding(elementID)
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
        }

        if mode.features.contains(.record) {
          Spacer()
          EditableKeyboardShortcutsButtons(keyboardShortcuts: $keyboardShortcuts, state: $state, mode: mode) {
            keyboardShortcuts.append(KeyShortcut.anyKey)
            reset()
          } onRecordButton: {
            if state == .recording {
              reset()
            } else {
              addButtonAction(proxy)
            }
          }
        }
      }
      .overlay(overlay(proxy))
      .onAppear {
        guard recordOnAppearIfEmpty, keyboardShortcuts.isEmpty else { return }

        addButtonAction(proxy)
      }
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
    .enableInjection()
  }

  private func handleEdit(_ id: KeyShortcut.ID) {
    switch mode {
    case .externalEdit(let then):
      then()
    case .inlineEdit:
      replacing = id
      record()
    }
  }

  private func overlay(_ proxy: ScrollViewProxy) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 6)
        .stroke(isGlowing
                ? Color(.systemRed) .opacity(0.5)
                : Color.clear, lineWidth: 2)
        .shadow(color: Color(.systemRed).opacity(isGlowing ? 1 : 0), radius: 6)
        .animation(Animation
          .easeInOut(duration: 1.25)
          .repeatForever(autoreverses: true), value: isGlowing)
        .opacity(state == .recording ? 1 : 0)

      Button(action: {
        addButtonAction(proxy)
      }, label: {
        HStack(spacing: 8) {
          Spacer()
          Text("Click to Record a Keyboard Shortcut")
            .allowsTightening(true)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
          Spacer()
          Divider()
            .opacity(0.5)
          Image(systemName: "record.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
        }
      })
      .environment(\.buttonPadding, .extraLarge)
      .fixedSize(horizontal: false, vertical: true)
      .opacity(keyboardShortcuts.isEmpty ? 1 : 0)
    }
  }

  private func addButtonAction(_ proxy: ScrollViewProxy) {
    let keyShortcut = KeyShortcut(id: placeholderId, key: "Recording ...")
    selectionManager.publish([keyShortcut.id])
    state = .recording
    recorderStore.mode = .recordKeystroke
    replacing = keyShortcut.id
    withAnimation(.smooth(duration: 0.25)) {
      keyboardShortcuts.append(keyShortcut)
      isGlowing = true
      selectedColor = Color(.systemRed)
    }

    DispatchQueue.main.async {
      withAnimation(animation) {
        proxy.scrollTo(keyShortcut.id)
      }
    }
  }

  private func record() {
    isGlowing = true
    withAnimation {
      state = .recording
      recorderStore.mode = .recordKeystroke
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
    keyboardShortcuts.removeAll(where: { $0.id == placeholderId })
  }
}

fileprivate struct EditableKeyboardShortcutsButtons<T: Hashable>: View {
  @Binding var keyboardShortcuts: [KeyShortcut]
  @Binding var state: EditableKeyboardShortcutsView<T>.CurrentState?
  private let mode: EditableKeyboardShortcutsView<T>.Mode
  private let onInsertAnyKey: () -> Void
  private let onRecordButton: () -> Void

  init(
    keyboardShortcuts: Binding<[KeyShortcut]>,
    state: Binding<EditableKeyboardShortcutsView<T>.CurrentState?>,
    mode: EditableKeyboardShortcutsView<T>.Mode,
    onInsertAnyKey: @escaping () -> Void,
    onRecordButton: @escaping () -> Void
  ) {
    _keyboardShortcuts = keyboardShortcuts
    _state = state
    self.mode = mode
    self.onInsertAnyKey = onInsertAnyKey
    self.onRecordButton = onRecordButton
  }

  var body: some View {
    HStack {
      Button(action: onInsertAnyKey, label: {
        Text("Insert Any Key")
          .font(.caption)
          .help("This means that any key can be used to end the sequence.")
      })
      .opacity((state == .recording && $keyboardShortcuts.count > 1) ? 1 : 0)

      RecordButton(mode: mode, state: $state, onAction: onRecordButton)
      .opacity(!keyboardShortcuts.isEmpty ? 1 : 0)
      .opacity(mode.features.contains(.record) ? 1 : 0)
    }
  }
}

fileprivate struct RecordButton<T: Hashable>: View {
  @Binding private var state: EditableKeyboardShortcutsView<T>.CurrentState?

  let mode: EditableKeyboardShortcutsView<T>.Mode
  let onAction: () -> Void

  init(mode: EditableKeyboardShortcutsView<T>.Mode,
       state: Binding<EditableKeyboardShortcutsView<T>.CurrentState?>,
       onAction: @escaping () -> Void) {
    self.mode = mode
    _state = state
    self.onAction = onAction
  }

  var body: some View {
    Button(action: onAction) {
      Image(systemName: state == .recording ? "stop.circle" : "record.circle.fill")
        .symbolRenderingMode(.palette)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundStyle(
          state == .recording ? Color(.white) : Color(.systemRed).opacity(0.8),
          state == .recording ? Color(.systemRed) : Color(nsColor: .darkGray)
        )
        .animation(.smooth, value: state)
        .frame(maxWidth: 14, maxHeight: 14)
    }
    .environment(\.buttonGrayscaleEffect, state == .recording ? false : true)
    .environment(\.buttonBackgroundColor, .systemRed)
    .environment(\.buttonPadding, .large)
    .environment(\.buttonHoverEffect, state == .recording ? false : true)
  }
}

private struct DraggableToggle<T: Transferable>: ViewModifier {
  let isEnabled: Bool
  let model: T

  func body(content: Content) -> some View {
    if isEnabled {
      content
        .draggable(model)
    } else {
      content
    }
  }
}

struct EditableKeyboardShortcutsView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    EditableKeyboardShortcutsView(
      $focus,
      focusBinding: { .detail(.keyboardShortcut($0)) },
      mode: .inlineEdit,
      keyboardShortcuts: .constant([ ]),
      draggableEnabled: false,
      state: .recording,
      selectionManager: SelectionManager<KeyShortcut>.init(),
      onTab: { _ in })
    .designTime()
    .padding()
  }
}
