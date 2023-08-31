import SwiftUI

struct ContentTypeImageView: View {
    var body: some View {
      RegularKeyIcon(letter: "(...)", width: 25, height: 25)
        .fixedSize()
        .frame(width: 24, height: 24)
    }
}

struct ContentTypeImageView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        ContentTypeImageView()
      }
      .frame(minWidth: 200, minHeight: 120)
      .padding()
    }
}
