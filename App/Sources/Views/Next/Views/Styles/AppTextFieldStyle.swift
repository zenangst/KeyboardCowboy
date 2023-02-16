import SwiftUI

struct AppTextFieldStyle: TextFieldStyle {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false

  func _body(configuration: TextField<_Label>) -> some View {
    configuration
      .textFieldStyle(.plain)
      .modifier(AppTextFieldViewModifier())
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(isFocused ? .controlAccentColor.withAlphaComponent(0.5) : .windowFrameTextColor), lineWidth: 1)
          .opacity(isFocused ? 0.75 : isHovered ? 0.15 : 0)
      )
      .shadow(color: isFocused ? .accentColor.opacity(0.8) : Color(.sRGBLinear, white: 0, opacity: 0.33),
              radius: isFocused ? 1.0 : 0.0)
      .onHover(perform: { newValue in  withAnimation { isHovered = newValue } })
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
