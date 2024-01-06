import SwiftUI

struct ContentTypeImageView: View {
    var body: some View {
      RegularKeyIcon(letter: "(...)", width: 22, height: 22)
        .fixedSize()
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
