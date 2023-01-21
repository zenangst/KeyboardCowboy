import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  enum CurrentState: Hashable {
    case recording
    case content(KeyShortcutRecording)
  }

  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore

  @ObserveInjection var inject
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

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
      }

      switch state {
      case .content(let model):
        switch model {
        case .valid(let keyShortcut),
            .systemShortcut(let keyShortcut),
            .delete(let keyShortcut),
            .cancel(let keyShortcut):
          HStack {
            if let modifiers = keyShortcut.modifiers {
              ForEach(modifiers) { modifier in
                switch modifier {
                case .function:
                  ModifierKeyIcon(key: modifier)
                    .frame(width: 36, height: 36)
                case .command, .shift:
                  ModifierKeyIcon(key: modifier)
                    .frame(width: 48, height: 36)
                default:
                  ModifierKeyIcon(key: modifier)
                    .frame(width: 36, height: 36)

                }
              }
            }
            RegularKeyIcon(letter: keyShortcut.key,
                           width: 36, height: 36)
            .fixedSize(horizontal: true, vertical: true)
            Spacer()

            Button(action: {
              withAnimation {
                state = .recording
                recorderStore.mode = .record
                isGlowing = true
              }
            }, label: {
              Text("Re-record")
            })
            .buttonStyle(.gradientStyle(config: .init(nsColor: .systemCyan)))


            Button(action: {
              state = .none
            }, label: {
              Text("Remove")
            })
            .buttonStyle(.destructiveStyle)
          }
        }
      case .recording:
        Button(action: {
          withAnimation {
            isGlowing = false
          }
        }) {
          RegularKeyIcon(letter: "Recording ...",
                         height: 36, glow: $isGlowing)
        }
      case .none:
        Button(action: {
          state = .recording
          recorderStore.mode = .record
          isGlowing = true
        }) {
          RegularKeyIcon(letter: "Record a keyboard shortcut",
                         height: 36)
        }
      }
    }
    .onChange(of: recorderStore.recording, perform: { newValue in
      guard let newValue else { return }
      state = .content(newValue)
    })
    .buttonStyle(.plain)
    .enableInjection()
  }
}

//struct NewCommandKeyboardShortcutView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandKeyboardShortcutView()
//  }
//}
