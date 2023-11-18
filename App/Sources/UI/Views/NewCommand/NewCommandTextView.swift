import SwiftUI

struct NewCommandTextView: View {
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation
  @State private var kind: TextCommand.Kind
  private let onSubmit: () -> Void

  init(payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>, onSubmit: @escaping () -> Void) {
    if case .text(let textCommand) = payload.wrappedValue {
      _kind = .init(initialValue: textCommand.kind) 
    } else {
      _kind = .init(initialValue: .insertText(.init("Hello, world!", mode: .instant)))
    }

    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit
  }

  var body: some View {
    Label(title: { Text("Text Command:") }, icon: { EmptyView() })
      .labelStyle(HeaderLabelStyle())
    Menu(content: {
      Button(action: {
        kind = .insertText(.init("", mode: .instant))
      }, label: {
        Text("Insert Text…")
      })
      Button(action: {
        kind = .setFindTo(.init(input: ""))
      }, label: {
        Text("Send Find to …")
      })
    }, label: {
      switch kind {
      case .setFindTo:
        Text("Send Find to …")
      case .insertText:
        Text("Insert Text")
      }
    })
    .menuStyle(.regular)

    switch kind {
    case .setFindTo:
      NewCommandSetFindToView($payload, validation: $validation, onSubmit: onSubmit)
    case .insertText:
      NewCommandTypeView($payload, validation: $validation, onSubmit: onSubmit)
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
      payload: .text(.init(.setFindTo(.init(input: "func")))),
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
