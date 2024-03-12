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
      case .inlineEdit: [.remove]
      case .externalEdit: []
      }
    }
  }

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
          LazyHStack(spacing: 0) {
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
              .padding(.leading, 2)
              .padding(.trailing, 4)
              .contentShape(Rectangle())
              .dropDestination(KeyShortcut.self, alignment: .horizontal, color: .accentColor, onDrop: { items, location in
                let ids = Array(selectionManager.selections)
                guard let (from, destination) = keyboardShortcuts.moveOffsets(for: keyboardShortcut.wrappedValue, with: ids) else {
                  return false
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                  keyboardShortcuts.move(fromOffsets: IndexSet(from), toOffset: destination)
                }

                return true
              })
              .contextMenu {
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
        Spacer()
        Button(action: {
          if state == .recording {
            reset()
          } else {
            addButtonAction(proxy)
          }
        },
               label: {
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
            .padding(1)
        })
        .buttonStyle(.calm(color: .systemRed, padding: .large))
        .opacity(!keyboardShortcuts.isEmpty ? 1 : 0)
        .padding(.trailing, 4)
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

  @ViewBuilder
  private func overlay(_ proxy: ScrollViewProxy) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 7)
        .stroke(isGlowing
                ? Color(.systemRed) .opacity(0.5)
                : Color.clear, lineWidth: 1)
        .padding(1)
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
            .padding(6)
            .frame(maxWidth: .infinity)
          Spacer()
          Divider()
            .opacity(0.5)
          Image(systemName: "record.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .padding(.trailing, 4)
        }
      })
      .buttonStyle(.positive)
      .fixedSize(horizontal: false, vertical: true)
      .padding(4)
      .opacity(keyboardShortcuts.isEmpty ? 1 : 0)
    }
  }

  private func addButtonAction(_ proxy: ScrollViewProxy) {
    let keyShortcut = KeyShortcut(id: placeholderId, key: "Recording ...", lhs: true)
    selectionManager.selections = [keyShortcut.id]
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

private struct DraggableToggle<T: Transferable>: ViewModifier {
  let isEnabled: Bool
  let model: T

  @ViewBuilder
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
