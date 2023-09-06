import SwiftUI

struct FileSystemTextFieldStyle: TextFieldStyle {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false

  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .textFieldStyle(.plain)
      .font(.headline)
      .padding(.vertical, 2.5)
      .padding(.horizontal, 5)
      .foregroundColor(.primary)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(isFocused ? .controlAccentColor : .windowFrameTextColor), lineWidth: 1)
          .opacity(isFocused ? 0.75 : isHovered ? 0.25 : 0)
      )
      .onHover(perform: { newValue in  withAnimation { isHovered = newValue } })
      .focused($isFocused)
  }
}
