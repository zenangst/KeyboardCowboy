import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  enum CurrentState: Hashable {
    case recording
  }

  @EnvironmentObject var recorderStore: KeyShortcutRecorderStore

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
        .overlay(NewCommandValidationView($validation).padding(-8))
        .frame(minHeight: 48)
        .padding(.horizontal, 6)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(nsColor: .windowBackgroundColor).opacity(0.25))
        )
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
      payload = .keyboardShortcut([])
    }
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
