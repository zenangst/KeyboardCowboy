import SwiftUI

struct ContentKeyboardImageView: View {
  let keys: [KeyShortcut]
  var body: some View {
    ZStack {
      ForEach(keys) { key in
        RegularKeyIcon(letter: key.key, width: 22, height: 22)
          .fixedSize()
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
