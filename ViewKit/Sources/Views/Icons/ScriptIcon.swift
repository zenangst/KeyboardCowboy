import SwiftUI

struct ScriptIcon: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.gray)
        .cornerRadius(12)
      Rectangle()
        .fill(Color.black)
        .cornerRadius(10)
        .padding(1)
        .shadow(radius: 1, y: 2)
      Text(">_")
        .font(Font.custom("Menlo", fixedSize: 14))
        .foregroundColor(.accentColor)
        .offset(x: -8, y: -8)
    }
    .frame(width: 50, height: 50)
    .shadow(radius: 2, y: 2)
    .padding(8)
  }
}

struct ScriptIcon_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ScriptIcon()
    }.background(Color.white)
  }
}
