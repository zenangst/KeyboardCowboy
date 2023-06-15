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
    VStack(alignment: .leading) {
      Label(title: { Text("Shortcut:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())
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
    .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray), fixedSize: false))
    .onChange(of: validation, perform: { newValue in
      guard newValue == .needsValidation else { return }
      withAnimation { validation = updateAndValidatePayload() }
    })
    .onAppear {
      validation = .unknown
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard let shortcut else { return .invalid(reason: "Pick a shortcut.") }

    payload = .shortcut(name: shortcut.name)

    return .valid
  }
}

struct NewCommandShortcutView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .shortcut,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}

