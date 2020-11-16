import SwiftUI

struct AddButton: View {
  enum Alignment: Hashable {
    case left, center, right
  }

  let text: String
  var alignment: Alignment = .left
  let action: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      if alignment == .center || alignment == .right { Spacer() }
      RoundOutlinedButton(title: "+", color: Color(.secondaryLabelColor))
        .onTapGesture(perform: action)
      Button(text, action: action)
        .buttonStyle(PlainButtonStyle())
      if alignment == .center || alignment == .left { Spacer() }
    }.padding(8)
  }
}
