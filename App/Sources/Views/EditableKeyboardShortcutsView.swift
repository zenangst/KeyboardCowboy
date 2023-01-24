import SwiftUI

struct EditableKeyboardShortcutsView: View {
  enum CurrentState: Hashable {
    case recording
  }
  @ObserveInjection var inject
  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore
  @Binding var keyboardShortcuts: [KeyShortcut]
  @State var state: CurrentState? = nil
  @State var isGlowing: Bool = false

  var body: some View {
    HStack {
      ScrollView(.horizontal) {
        EditableStack(
          $keyboardShortcuts,
          axes: .horizontal,
          onMove: { keyboardShortcuts.move(fromOffsets: $0, toOffset: $1) },
          onDelete: { offsets in
            withAnimation(.easeOut(duration: 0.2)) {
              keyboardShortcuts.remove(atOffsets: offsets)
            }
          },
          content: { keyboardShortcut in
            HStack(spacing: 6) {
              ForEach(keyboardShortcut.wrappedValue.modifiers) { modifier in
                ModifierKeyIcon(key: modifier)
                  .frame(minWidth: modifier == .command || modifier == .shift ? 44 : 32, minHeight: 32)
                  .fixedSize(horizontal: true, vertical: true)
              }
              RegularKeyIcon(letter: keyboardShortcut.wrappedValue.key, width: 32, height: 32)
                .fixedSize(horizontal: true, vertical: true)
            }
            .contextMenu {
              Text(keyboardShortcut.wrappedValue.validationValue)
              Divider()
              Button(action: {
                if let index = keyboardShortcuts.firstIndex(where: { $0.id == keyboardShortcut.id }) {
                  _ = withAnimation(.easeOut(duration: 0.2)) {
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
        withAnimation {
          isGlowing = true
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
                    : Color.clear, lineWidth: 2)
            .padding(-2)
            .animation(Animation
              .easeInOut(duration: 1.25)
              .repeatForever(autoreverses: true), value: isGlowing)
        }
      }
    )
    .onChange(of: recorderStore.recording, perform: { newValue in
      guard state == .recording, let newValue else { return }
      switch newValue {
      case .valid(let newKeyboardShortcut):
        withAnimation(.spring()) {
          keyboardShortcuts.append(newKeyboardShortcut)
          state = nil
          isGlowing = false
        }
      default:
        break
      }
    })
    .enableInjection()
  }
}
