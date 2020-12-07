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
      Button(action: action, label: {
        Label(
          title: { Text(text) },
          icon: { Image(systemName: "plus.circle") }
        )
      }).buttonStyle(PlainButtonStyle())
      if alignment == .center || alignment == .left { Spacer() }
    }.padding(8)
  }
}
