import SwiftUI

struct ScriptSymbol: View {
  let cornerRadius: CGFloat
  let foreground: Color
  let background: Color
  let borderColor: Color

  init(cornerRadius: CGFloat = 11,
       foreground: Color,
       background: Color,
       borderColor: Color) {
    self.cornerRadius = cornerRadius
    self.foreground = foreground
    self.background = background
    self.borderColor = borderColor
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(background)
          .padding(proxy.size.height * 0.075)

        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(borderColor, lineWidth: 1)
          .padding(proxy.size.height * 0.05)

        Text(">_")
          .font(Font.custom(
            "Menlo",
            fixedSize: proxy.size.width * 0.20,
          ))
          .foregroundColor(foreground)
          .contrast(0.75)
          .padding([.top, .leading], proxy.size.height * 0.2)
      }
    }
  }
}

struct ScriptSymbol_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ScriptSymbol(foreground: .orange,
                   background: .yellow,
                   borderColor: .black)
    }
    .background(Color.white)
    .frame(width: 128, height: 128)
  }
}
