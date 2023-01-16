import SwiftUI

struct NewCommandTypeView: View {
  @ObserveInjection var inject
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation

  @State private var text: String = ""
  private let onSubmit: () -> Void

  init(_ payload: Binding<NewCommandPayload>,
       validation: Binding<NewCommandValidation>,
       onSubmit: @escaping () -> Void) {
    _payload = payload
    _validation = validation
    self.onSubmit = onSubmit
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Type text:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())
      TypeCommandTextEditor(text: $text, onCommandReturnKey: onSubmit)
    }
    .onChange(of: text) { newValue in
      validation = updateAndValidatePayload()
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    guard !text.isEmpty else { return .invalid(reason: "Pick a shortcut.") }

    payload = .type(text: text)

    return .valid
  }
}

//struct NewCommandTypeView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandTypeView()
//  }
//}
