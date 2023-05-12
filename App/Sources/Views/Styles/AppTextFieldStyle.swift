import SwiftUI

struct AppTextFieldStyle: TextFieldStyle {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false

  func _body(configuration: TextField<_Label>) -> some View {
    configuration
      .textFieldStyle(.plain)
      .modifier(AppTextFieldViewModifier())
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4 + 1.5)
            .strokeBorder(Color.accentColor, lineWidth: 1.5)
            .padding(-1.5)
          RoundedRectangle(cornerRadius: 4 + 2.5)
            .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1.5)
            .padding(-2.5)
        }
          .compositingGroup()
          .opacity(isFocused ? 1 : isHovered ? 0.5 : 0)
          .grayscale(isFocused ? 0 : 1)
      )
      .compositingGroup()
      .onHover(perform: { newValue in
        isHovered <- newValue
      })
      .focusable()
      .focused($isFocused)
  }
}

struct AppTextFieldViewModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(2.5)
      .font(.body)
      .bold()
  }
}
