import Bonzai
import SwiftUI

struct NewCommandSetFindToView: View {
  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation
  @State private var text = ""
  private let onSubmit: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       text: String = "",
       onSubmit: @escaping () -> Void) {
    _payload = payload
    _validation = validation
    _text = .init(initialValue: text)
    self.onSubmit = onSubmit
  }

  var body: some View {
    TextField("Value", text: $text)
      .onSubmit {
        update()
        onSubmit()
      }
      .onChange(of: text, perform: { value in
        update()
      })
      .textFieldStyle(.regular(nil))
      .onAppear {
        update()
      }
  }

  private func update() {
    payload = .text(.init(.setFindTo(.init(input: text))))
    validation = .valid

  }
}
