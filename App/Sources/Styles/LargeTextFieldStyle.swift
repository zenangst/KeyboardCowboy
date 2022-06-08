import SwiftUI

struct LargeTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .textFieldStyle(PlainTextFieldStyle())
      .foregroundColor(.primary)
      .font(.largeTitle)
  }
}
