import Bonzai
import SwiftUI

struct NewCommandTextView: View {
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#type-commands")!
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation
  @State private var kind: TextCommand.Kind
  private let onSubmit: () -> Void

  init(payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>, onSubmit: @escaping () -> Void) {
    if case .text(let textCommand) = payload.wrappedValue {
      _kind = .init(initialValue: textCommand.kind) 
    } else {
      _kind = .init(initialValue: .insertText(.init("Hello, world!", mode: .instant, actions: [])))
    }

    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit
  }

  var body: some View {
    HStack {
      ZenLabel("Text Command:")
      Spacer()
      Button(action: { NSWorkspace.shared.open(wikiUrl) },
             label: { Image(systemName: "questionmark.circle.fill") })
    }


    HStack {
      TypingIconView(size: 24)
      Menu(content: {
        Button(action: {
          kind = .insertText(TextCommand.TypeCommand("", mode: .instant, actions: []))
        }, label: {
          Text("Insert Text…")
        })
      }, label: {
        switch kind {
        case .insertText:
          Text("Insert Text")
        }
      })
    }
    .padding(.bottom, 8)

    switch kind {
    case .insertText:
      NewCommandTypeView($payload, validation: $validation, onSubmit: onSubmit)
        .roundedStyle()
    }
  }
}

struct NewCommandTextView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .text,
      payload: .text(.init(.insertText(.init("", mode: .instant, actions: [])))),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
