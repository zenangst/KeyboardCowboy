import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  enum CurrentState: Hashable {
    case recording
  }

  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore

  @ObserveInjection var inject
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State var keyboardShortcuts = [KeyShortcut]()
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

      HStack {
        EditableKeyboardShortcutsView(keyboardShortcuts: $keyboardShortcuts)
          .overlay(
            ZStack {
              if keyboardShortcuts.isEmpty {
                HStack {
                  Spacer()
                  Text("Press the plus (+) button to record a keyboard shortcut")
                    .font(.footnote)
                  Spacer()
                }
              }
            }
          )
        Spacer()
        Button(action: {
          state = .recording
          recorderStore.mode = .record
          isGlowing = true
        },
               label: { Image(systemName: "plus").frame(width: 10, height: 10) })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
          .padding(.trailing, 4)
      }
      .overlay(NewCommandValidationView($validation).padding(-8))
      .frame(minHeight: 48)
      .padding(.horizontal, 6)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(nsColor: .windowBackgroundColor).opacity(0.25))
      )

      switch state {
      case .recording:
        RegularKeyIcon(letter: "Recording ...",
                       height: 36, glow: $isGlowing)
      case .none:
        EmptyView()
      }
    }
    .onChange(of: recorderStore.recording, perform: { newValue in
      guard let newValue else { return }
      switch newValue {
      case .valid(let newKeyboardShortcut):
        withAnimation(.spring()) {
          keyboardShortcuts.append(newKeyboardShortcut)
          state = nil
        }
      default:
        break
      }
    })
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      validation = updateAndValidatePayload()
    })
    .onAppear {
      validation = .unknown
      payload = .keyboardShortcut([])
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

//struct NewCommandKeyboardShortcutView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandKeyboardShortcutView()
//  }
//}
