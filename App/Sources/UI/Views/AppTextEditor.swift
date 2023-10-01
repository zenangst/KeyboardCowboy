import SwiftUI

struct AppTextEditor: View {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false
  @Binding var text: String

  private let font: Font
  private let placeholder: String
  private let onCommandReturnKey: (() -> Void)?

  init(text: Binding<String>, 
       placeholder: String,
       font: Font = .body,
       onCommandReturnKey: (() -> Void)? = nil) {
    _text = text
    self.placeholder = placeholder
    self.font = font
    self.onCommandReturnKey = onCommandReturnKey
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      TextEditor(text: $text)
        .scrollContentBackground(.hidden)
        .font(font)
        .padding([.top, .leading, .bottom], 4)
        .scrollIndicators(.hidden)
        .background(alignment: .leading,
                    content: {
          RoundedRectangle(cornerRadius: 4)
            .fill(
              Color(isFocused
                    ? .controlAccentColor.withAlphaComponent(0.5)
                    : .windowFrameTextColor.withAlphaComponent(0.15)
              )
            )
            .frame(width: 5)
        })
      Text(placeholder)
        .font(font)
        .animation(nil, value: text.isEmpty)
        .opacity(text.isEmpty ? 0.5 : 0)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .allowsHitTesting(false)
        .padding(.top, 4)
        .padding(.leading, 8)
      Button("", action: { onCommandReturnKey?() })
        .opacity(0.0)
        .keyboardShortcut(.return, modifiers: [.command])
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(Color(isFocused ? .controlAccentColor.withAlphaComponent(0.5) : .windowFrameTextColor))
        .opacity(isFocused ? 0.15 : isHovered ? 0.015 : 0)
    )
    .background(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(isFocused ? .controlAccentColor.withAlphaComponent(0.5) : .windowFrameTextColor), lineWidth: 1)
        .opacity(isFocused ? 0.75 : isHovered ? 0.15 : 0)

    )
    .onHover(perform: { newValue in  withAnimation(.easeInOut(duration: 0.2)) { isHovered = newValue } })
    .focused($isFocused)
  }
}

struct AppTextEditor_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      AppTextEditor(text: .readonly(""), placeholder: "Enter text ...")
      AppTextEditor(text: .constant("""
#!/usr/bin/env bash

echo "hello world"
"""), placeholder: "Script goes here…", font: Font.system(.body, design: .monospaced))
    }
  }
}
