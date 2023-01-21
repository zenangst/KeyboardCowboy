import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  enum CurrentState: Hashable {
    case recording
    case content
  }

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
      case .content:
          HStack {
            ModifierKeyIcon(key: .function)
              .frame(width: 36, height: 36)
            RegularKeyIcon(letter: "C",
                           width: 36, height: 36)
            .fixedSize(horizontal: true, vertical: true)
            Spacer()

            Button(action: {
              withAnimation {
                state = .recording
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
      case .recording:
        Button(action: {
          withAnimation {
            state = .content
            isGlowing = false
          }
        }) {
          RegularKeyIcon(letter: "Recording ...",
                         height: 36, glow: $isGlowing)
        }
      case .none:
        Button(action: {
          state = .recording
          isGlowing = true
        }) {
          RegularKeyIcon(letter: "Record a keyboard shortcut",
                         height: 36)
        }
      }
    }
    .buttonStyle(.plain)
    .enableInjection()
  }
}

//struct NewCommandKeyboardShortcutView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandKeyboardShortcutView()
//  }
//}
