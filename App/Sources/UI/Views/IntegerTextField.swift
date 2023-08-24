import SwiftUI

struct IntegerTextField: View {
  @Binding var text: String

  private let onValidChange: (String) -> Void

  init(text: Binding<String>, onValidChange: @escaping (String) -> Void) {
    _text = text
    self.onValidChange = onValidChange
  }

  var body: some View {
    TextField("", text: Binding<String>(get: {
      text
    }, set: { newValue in
      if newValue.contains(where: { !$0.isNumber }) {
        return
      }
      text = newValue
      onValidChange(newValue)
    }))
  }
}

