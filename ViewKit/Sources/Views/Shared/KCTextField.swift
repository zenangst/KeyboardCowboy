import SwiftUI

struct KCTextField: View {
  @Binding var value: String
  @Environment(\.redactionReasons) private var reasons

  var body: some View {
    if reasons.isEmpty {
      TextField("", text: $value)
    } else {
      Text($value.wrappedValue)
        .frame(alignment: .leading)
    }
  }
}

struct KCTextFieldPreviews: PreviewProvider {
  static var previews: some View {
    Group {
      KCTextField(value: .constant("This is a test string."))
      KCTextField(value: .constant("This is a test string."))
        .redacted(reason: .placeholder)
    }.frame(width: 200, height: 50, alignment: .center)

  }
}
