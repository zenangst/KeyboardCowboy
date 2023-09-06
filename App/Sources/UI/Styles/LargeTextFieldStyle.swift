import SwiftUI

struct LargeTextFieldStyle: TextFieldStyle {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false

  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .textFieldStyle(.plain)
      .padding(.vertical, 2.5)
      .padding(.horizontal, 5)
      .foregroundColor(.primary)
      .font(.largeTitle)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(isFocused ? .controlAccentColor : .windowFrameTextColor), lineWidth: 2)
          .compositingGroup()
          .shadow(color: Color(isFocused ? .controlAccentColor : .clear), radius: 2)
          .opacity(isFocused ? 0.75 : isHovered ? 0.25 : 0)
      )
      .fixedSize(horizontal: false, vertical: true)
      .onHover(perform: { newValue in  withAnimation { isHovered <- newValue } })
      .focused($isFocused)
  }
}
