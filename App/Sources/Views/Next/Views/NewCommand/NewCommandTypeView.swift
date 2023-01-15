import SwiftUI

struct NewCommandTypeView: View {
  @ObserveInjection var inject
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandView.Validation

  @State private var text: String = ""

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandView.Validation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      Label(title: { Text("Type text:") }, icon: { EmptyView() })
        .labelStyle(HeaderLabelStyle())

      TextEditor(text: $text)
    }
    .onChange(of: text) { newValue in
      validation = updateAndValidatePayload()
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandView.Validation {
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
