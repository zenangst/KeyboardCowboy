import SwiftUI

struct NewCommandTypeView: View {
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#type-commands")!

  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var text: String = ""
  @State private var mode: TypeCommand.Mode = .instant
  private let onSubmit: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       onSubmit: @escaping () -> Void) {
    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit

    if case .type(let text, let mode) = _payload.wrappedValue {
      _text = .init(initialValue: text)
      _mode = .init(initialValue: mode)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Label(title: { Text("Type text:") }, icon: { EmptyView() })
          .labelStyle(HeaderLabelStyle())
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
        .buttonStyle(.calm(color: .systemYellow, padding: .small))
      }
      AppTextEditor(text: $text, placeholder: "Enter text…", onCommandReturnKey: onSubmit)

      Menu(content: {
        ForEach(TypeCommand.Mode.allCases) { mode in
          Button(action: {
            self.mode = mode
            self.validation = updateAndValidatePayload()
          },
                 label: { Text(mode.rawValue) })
        }
      }, label: {
        Text(mode.rawValue)
      })
      .menuStyle(.regular)
    }
    .onChange(of: text) { newValue in
      validation = updateAndValidatePayload()
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard !text.isEmpty else { return .invalid(reason: "Pick a shortcut.") }

    payload = .type(text: text, mode: mode)

    return .valid
  }
}

struct NewCommandTypeView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .type,
      payload: .type(text: "Hello, world!", mode: .instant),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
