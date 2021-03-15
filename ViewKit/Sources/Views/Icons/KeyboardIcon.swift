import SwiftUI

struct KeyboardIcon: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.gray)
        .cornerRadius(6)
      Rectangle()
        .fill(Color.black)
        .cornerRadius(6)
        .padding(1)
        .shadow(radius: 1, y: 2)
      Text("⌘")
        .font(Font.custom("Menlo", fixedSize: 18))
        .offset(x: 16, y: -12)
      Text("command")
        .font(Font.custom("Menlo", fixedSize: 10))
        .offset(x: 0, y: 12)
    }
    .frame(width: 60, height: 48)
    .shadow(radius: 2, y: 2)
    .padding(8)
  }
}

struct KeyboardIcon_Previews: PreviewProvider {
  static var previews: some View {
    KeyboardIcon()
  }
}
