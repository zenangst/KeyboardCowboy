import SwiftUI

struct NewCommandShortcutView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var shortcut: Shortcut? = nil

  @EnvironmentObject var shortcutStore: ShortcutStore

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    HStack {
      Label(title: { Text("Shortcut:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())
      Spacer()
      Menu {
        ForEach(shortcutStore.shortcuts, id: \.name) { shortcut in
          Button(shortcut.name, action: {
            self.shortcut = shortcut
            validation = updateAndValidatePayload()
          })
        }
      } label: {
        if let shortcut {
          Text(shortcut.name)
        } else {
          Text("Select shortcut")
        }
      }
      .background(NewCommandValidationView($validation))
    }
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      withAnimation { validation = updateAndValidatePayload() }
    })
    .onAppear {
      validation = .unknown
      payload = NewCommandPayload.script(value: "", kind: .source, scriptExtension: .appleScript)
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard let shortcut else { return .invalid(reason: "Pick a shortcut.") }

    payload = .shortcut(name: shortcut.name)

    return .valid
  }
}

//struct NewCommandShortcutView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewCommandShortcutView()
//    }
//}
