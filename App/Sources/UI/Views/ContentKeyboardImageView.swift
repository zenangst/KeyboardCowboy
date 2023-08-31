import SwiftUI

struct ContentKeyboardImageView: View {
  let keys: [KeyShortcut]
  var body: some View {
    ZStack {
      ForEach(keys) { key in
        RegularKeyIcon(letter: key.key)
          .fixedSize()
          .scaleEffect(0.8)

        ForEach(key.modifiers) { modifier in
          HStack {
            ModifierKeyIcon(key: modifier)
              .scaleEffect(0.4, anchor: .bottomLeading)
              .opacity(0.8)
              .fixedSize()
          }
          .padding(4)
        }
      }
    }
  }
}

struct ContentKeyboardImageView_Previews: PreviewProvider {
  static var previews: some View {
    ContentKeyboardImageView(keys: [
      .init(key: "", modifiers: [.command]),
      .init(key: "C", modifiers: []),
    ])
    .frame(minWidth: 200, minHeight: 120)
    .padding()
  }
}
