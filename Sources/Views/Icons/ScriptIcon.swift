import SwiftUI

struct ScriptIcon: View {
  let cornerRadius: CGFloat

  init(cornerRadius: CGFloat = 11) {
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.white)
        Rectangle()
          .fill(Color.clear)
          .cornerRadius(cornerRadius)
          .padding(1)
          .shadow(radius: 1, y: 2)
        Text(">_")
          .font(Font.custom(
                  "Menlo",
                  fixedSize: proxy.size.width * 0.30))
          .foregroundColor(.white)
          .offset(x: proxy.size.width * 0.1,
                  y: proxy.size.height * 0.1)
      }
      .shadow(radius: 2, y: 2)
    }
  }
}

struct ScriptIcon_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ScriptIcon()
    }
    .background(Color.white)
    .frame(width: 128, height: 128)
  }
}
