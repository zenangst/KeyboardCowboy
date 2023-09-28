import SwiftUI

struct CommandSymbolIcon: View {
  let background: Color
  let textColor: Color

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        GeometryReader { proxy in
          RoundedRectangle(cornerRadius: 3)
            .fill(background)

          Group {
            Text("⌘")
              .foregroundColor(textColor)
              .contrast(0.5)
              .font(Font.system(size: proxy.size.width * 0.17, weight: .regular, design: .rounded))
          }
          .frame(width: proxy.size.width, alignment: .trailing)
          .offset(x: -proxy.size.width * 0.075,
                  y: proxy.size.width * 0.065)

          Group {
            Text("command")
              .foregroundColor(textColor)
              .contrast(0.5)
              .font(Font.system(size: proxy.size.width * 0.17, weight: .regular, design: .rounded))
          }
          .frame(width: proxy.size.width, height: proxy.size.height,
                 alignment: .bottom)
          .offset(y: -proxy.size.width * 0.065)
        }
      }
      .padding([.top, .bottom], proxy.size.width * 0.2)
    }
  }
}

struct CommandSymbolIcon_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      CommandSymbolIcon(background: .white,
                        textColor: Color.green)
      .frame(width: 128, height: 128)
    }.background(Color.black)
  }
}
