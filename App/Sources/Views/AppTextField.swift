import SwiftUI

struct AppTextField: View {
  enum TextFieldState: Equatable {
    case content
    case editing
  }

  @FocusState var isFocused: Bool?
  @State var state: TextFieldState
  @Binding var text: String

  init(_ state: TextFieldState = .content,
       text: Binding<String>) {
    _state = .init(initialValue: state)
    _text = text
  }

  var body: some View {
    Group {
      switch state {
      case .content:
        Text(text)
          .modifier(AppTextFieldViewModifier())
          .allowsTightening(true)
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(RoundedRectangle(cornerRadius: 4))
      case .editing:
        TextField("", text: $text)
          .textFieldStyle(AppTextFieldStyle())
          .focused($isFocused, equals: true)
      }
    }
    .onTapGesture {
      state = state == .content ? .editing : .content
      isFocused = true
    }
  }
}

struct AppTextField_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      AppTextField(.content, text: .constant("Hello world"))
      AppTextField(.editing, text: .constant("Hello world"))
    }
    .padding()
  }
}
