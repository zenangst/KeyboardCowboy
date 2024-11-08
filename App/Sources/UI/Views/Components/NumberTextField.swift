import Foundation
import SwiftUI

struct NumberTextField: View {
  @Binding var text: String

  private let onValidChange: (String) -> Void

  init(text: Binding<String>, onValidChange: @escaping (String) -> Void) {
    _text = text
    self.onValidChange = onValidChange
  }

  var body: some View {
    TextField("", text: Binding<String>(get: { text }, set: { newValue in
      let chars = CharacterSet(charactersIn: "0123456789.,")
      newValue.unicodeScalars.forEach { char in
        guard !chars.contains(char) else { return }
        return
      }
      text = newValue
      onValidChange(newValue)
    }))
  }
}

