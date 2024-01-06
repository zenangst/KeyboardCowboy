import Bonzai
import SwiftUI

struct NewCommandTypeView: View {
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#type-commands")!

  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var text: String = ""
  @State private var mode: TextCommand.TypeCommand.Mode = .instant
  private let onSubmit: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       onSubmit: @escaping () -> Void) {
    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit

    if case .text(let model) = _payload.wrappedValue,
       case .insertText(let textModel) = model.kind {
      _text = .init(initialValue: textModel.input)
      _mode = .init(initialValue: textModel.mode)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Type text:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
        .buttonStyle(.calm(color: .systemYellow, padding: .small))
      }
      ZenTextEditor(text: $text, placeholder: "Enter text…", onCommandReturnKey: onSubmit)

      Menu(content: {
        ForEach(TextCommand.TypeCommand.Mode.allCases) { mode in
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

    payload = .text(.init(.insertText(.init(text, mode: mode, meta: .init(name: "")))))

    return .valid
  }
}

struct NewCommandTypeView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .text,
      payload: .text(.init(.insertText(.init("", mode: .instant)))),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
