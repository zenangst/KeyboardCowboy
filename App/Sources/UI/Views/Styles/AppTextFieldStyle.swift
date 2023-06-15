import SwiftUI

struct AppTextFieldStyle: TextFieldStyle {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false
  private let color: Color
  private let font: Font

  init(_ font: Font = .body, color: Color = .accentColor) {
    self.color = color
    self.font = font
  }

  func _body(configuration: TextField<_Label>) -> some View {
    HStack {
      configuration
        .textFieldStyle(.plain)
        .modifier(AppTextFieldViewModifier(font))
        .background(
          ZStack {
            RoundedRectangle(cornerRadius: 4 + 1.5)
              .strokeBorder(color, lineWidth: 1.5)
              .padding(-1.5)
            RoundedRectangle(cornerRadius: 4 + 2.5)
              .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
              .padding(-2.5)
          }
            .compositingGroup()
            .opacity(isFocused ? 1 : isHovered ? 0.5 : 0)
            .grayscale(isFocused ? 0 : 1)
        )
        .padding(2.5)
        .compositingGroup()
        .onHover(perform: { newValue in
          isHovered <- newValue
        })
        .focusable()
        .focused($isFocused)
    }
  }
}

struct AppTextFieldViewModifier: ViewModifier {
  private let font: Font

  init(_ font: Font = .body) {
    self.font = font
  }

  func body(content: Content) -> some View {
    content
      .padding(2.5)
      .font(font)
      .bold()
  }
}
