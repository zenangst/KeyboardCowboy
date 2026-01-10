import Bonzai
import SwiftUI

struct NewCommandTypeView: View {
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var text: String = ""
  @State private var mode: TextCommand.TypeCommand.Mode = .instant
  @State private var actions: Set<TextCommand.TypeCommand.Action> = []

  @State private var insertEnter: Bool = false

  private let onSubmit: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       onSubmit: @escaping () -> Void) {
    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit

    if case let .text(model) = _payload.wrappedValue,
       case let .insertText(textModel) = model.kind {
      _text = .init(initialValue: textModel.input)
      _mode = .init(initialValue: textModel.mode)
      _actions = .init(initialValue: textModel.actions)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZenTextEditor(text: $text, placeholder: "Enter text…", onCommandReturnKey: onSubmit)

      Grid(alignment: .trailing) {
        GridRow {
          Text("Actions:")
          HStack {
            Toggle(isOn: $insertEnter, label: {})
              .onChange(of: insertEnter) { _ in
                if actions.contains(.insertEnter) {
                  actions.remove(.insertEnter)
                } else {
                  actions.insert(.insertEnter)
                }
                validation = updateAndValidatePayload()
              }
            Text(TextCommand.TypeCommand.Action.insertEnter.displayValue)
            Spacer()
          }
        }
        GridRow {
          Text("Mode:")
          Menu(content: {
            ForEach(TextCommand.TypeCommand.Mode.allCases) { mode in
              Button(action: {
                       self.mode = mode
                       validation = updateAndValidatePayload()
                     },
                     label: { Text(mode.rawValue) })
            }
          }, label: {
            Text(mode.rawValue)
          })
        }
      }
      .roundedStyle()
    }
    .onChange(of: text) { _ in
      validation = updateAndValidatePayload()
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard !text.isEmpty else { return .invalid(reason: "Please type something...") }

    payload = .text(.init(.insertText(.init(text, mode: mode, meta: .init(name: ""), actions: actions))))

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
      payload: .text(.init(.insertText(.init("", mode: .instant, actions: [])))),
      onDismiss: {},
      onSave: { _, _ in },
    )
    .designTime()
  }
}
