import SwiftUI

struct EditableKeyboardShortcutsView: View {
  enum CurrentState: Hashable {
    case recording
  }
  @ObserveInjection var inject
  @Environment(\.controlActiveState) var controlActiveState
  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore
  @Binding var keyboardShortcuts: [KeyShortcut]
  @State var state: CurrentState? = nil
  @State var isGlowing: Bool = false
  @State var replacing: KeyShortcut.ID?
  @State var selectedColor: Color = .accentColor

  private let placeholderId = "keyboard_shortcut_placeholder_id"
  private let animation: Animation = .easeOut(duration: 0.2)

  var body: some View {
    HStack {
      ScrollView(.horizontal) {
        EditableStack(
          $keyboardShortcuts,
          axes: .horizontal,
          selectedColor: $selectedColor,
          onClick: { id, index in
            if replacing == id {
              record()
            }
            replacing = id
          },
          onMove: { keyboardShortcuts.move(fromOffsets: $0, toOffset: $1) },
          onDelete: { offsets in
            withAnimation(animation) {
              keyboardShortcuts.remove(atOffsets: offsets)
            }
          },
          content: { keyboardShortcut in
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
              Button(action: {
                if let index = keyboardShortcuts.firstIndex(where: { $0.id == keyboardShortcut.id }) {
                  _ = withAnimation(animation) {
                    keyboardShortcuts.remove(at: index)
                  }
                }
              }, label: {
                Text("Remove")
              })
            }
            .padding(4)
            .background(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.disabledControlTextColor))
                .opacity(0.5)
            )
          })
        .padding(4)
      }
      Spacer()
      Button(action: {
        state = .recording
        recorderStore.mode = .record
        let keyShortcut = KeyShortcut(id: placeholderId, key: "Recording ...", lhs: true)
        replacing = keyShortcut.id
        keyboardShortcuts.append(keyShortcut)
        withAnimation(animation) {
          isGlowing = true
          selectedColor = Color(.systemRed)
        }
      },
             label: { Image(systemName: "plus").frame(width: 10, height: 10) })
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
        .padding(.trailing, 4)
    }
    .overlay(
      ZStack {
        if keyboardShortcuts.isEmpty {
          HStack {
            Spacer()
            Text("Press the plus (+) button to record a keyboard shortcut")
              .font(.footnote)
            Spacer()
          }
          .padding(4)
        }
        if state == .recording {
          RoundedRectangle(cornerRadius: 4)
            .stroke(isGlowing
                    ? Color(.systemRed) .opacity(0.5)
                    : Color.clear, lineWidth: 1)
            .animation(Animation
              .easeInOut(duration: 1.25)
              .repeatForever(autoreverses: true), value: isGlowing)
        }
      }
    )
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
    recorderStore.mode = .intercept
    withAnimation(animation) {
      keyboardShortcuts.removeAll(where: { $0.id == placeholderId })
    }
  }
}
